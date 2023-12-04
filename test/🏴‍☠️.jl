@eval Distributed function message_handler_loop(r_stream::IO, w_stream::IO, incoming::Bool)
    wpid=0          # the worker r_stream is connected to.
    boundary = similar(MSG_BOUNDARY)
    try
        version = process_hdr(r_stream, incoming)
        serializer = ClusterSerializer(r_stream)

        # The first message will associate wpid with r_stream
        header = deserialize_hdr_raw(r_stream)
        msg = deserialize_msg(serializer)
        handle_msg(msg, header, r_stream, w_stream, version)
        wpid = worker_id_from_socket(r_stream)
        @assert wpid > 0

        readbytes!(r_stream, boundary, length(MSG_BOUNDARY))

        while !eof(r_stream)
            reset_state(serializer)
            header = deserialize_hdr_raw(r_stream)
            # println("header: ", header)

            try
                msg = invokelatest(deserialize_msg, serializer)
            catch e
                # Deserialization error; discard bytes in stream until boundary found
                boundary_idx = 1
                while true
                    # This may throw an EOF error if the terminal boundary was not written
                    # correctly, triggering the higher-scoped catch block below
                    byte = read(r_stream, UInt8)
                    if byte == MSG_BOUNDARY[boundary_idx]
                        boundary_idx += 1
                        if boundary_idx > length(MSG_BOUNDARY)
                            break
                        end
                    else
                        boundary_idx = 1
                    end
                end

                # remotecalls only rethrow RemoteExceptions. Any other exception is treated as
                # data to be returned. Wrap this exception in a RemoteException.
                remote_err = RemoteException(myid(), CapturedException(e, catch_backtrace()))
                # println("Deserialization error. ", remote_err)
                if !null_id(header.response_oid)
                    ref = lookup_ref(header.response_oid)
                    put!(ref, remote_err)
                end
                if !null_id(header.notify_oid)
                    deliver_result(w_stream, :call_fetch, header.notify_oid, remote_err)
                end
                continue
            end
            readbytes!(r_stream, boundary, length(MSG_BOUNDARY))

            # println("got msg: ", typeof(msg))
            handle_msg(msg, header, r_stream, w_stream, version)
        end
    catch e
        werr = worker_from_id(wpid)
        oldstate = werr.state

        # Check again as it may have been set in a message handler but not propagated to the calling block above
        if wpid < 1
            wpid = worker_id_from_socket(r_stream)
        end

        if wpid < 1
            println(stderr, e, CapturedException(e, catch_backtrace()))
            println(stderr, "Process($(myid())) - Unknown remote, closing connection.")
        elseif !(wpid in map_del_wrkr)
            set_worker_state(werr, W_TERMINATED)

            # If unhandleable error occurred talking to pid 1, exit
            if wpid == 1
                if isopen(w_stream)
                    @error "Fatal error on process $(myid())" exception=e,catch_backtrace()
                end
                exit(1)
            end

            # Will treat any exception as death of node and cleanup
            # since currently we do not have a mechanism for workers to reconnect
            # to each other on unhandled errors
            deregister_worker(wpid)
        end

        close(r_stream)
        close(w_stream)

        if (myid() == 1) && (wpid > 1)
            if oldstate != W_TERMINATING
                println(stderr, "Worker $wpid terminated.")
                rethrow()
            end
        end

        return nothing
    end
end
