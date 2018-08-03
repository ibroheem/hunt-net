module hunt.net.ssl.SSLEngineResult;

import hunt.util.exception;

import std.conv;

/**
 * An <code>SSLEngineResult</code> enum describing the current
 * handshaking state of this <code>SSLEngine</code>.
 *
 * @author Brad R. Wetmore
 * @since 1.5
 */
enum HandshakeStatus {

    /**
     * The <code>SSLEngine</code> is not currently handshaking.
     */
    NOT_HANDSHAKING,

    /**
     * The <code>SSLEngine</code> has just finished handshaking.
     * <P>
     * This value is only generated by a call to
     * <code>SSLEngine.wrap()/unwrap()</code> when that call
     * finishes a handshake.  It is never generated by
     * <code>SSLEngine.getHandshakeStatus()</code>.
     *
     * @see SSLEngine#wrap(ByteBuffer, ByteBuffer)
     * @see SSLEngine#unwrap(ByteBuffer, ByteBuffer)
     * @see SSLEngine#getHandshakeStatus()
     */
    FINISHED,

    /**
     * The <code>SSLEngine</code> needs the results of one (or more)
     * delegated tasks before handshaking can continue.
     *
     * @see SSLEngine#getDelegatedTask()
     */
    NEED_TASK,

    /**
     * The <code>SSLEngine</code> must send data to the remote side
     * before handshaking can continue, so <code>SSLEngine.wrap()</code>
     * should be called.
     *
     * @see SSLEngine#wrap(ByteBuffer, ByteBuffer)
     */
    NEED_WRAP,

    /**
     * The <code>SSLEngine</code> needs to receive data from the
     * remote side before handshaking can continue.
     */
    NEED_UNWRAP
}

/**
 * An encapsulation of the result state produced by
 * <code>SSLEngine</code> I/O calls.
 *
 * <p> A <code>SSLEngine</code> provides a means for establishing
 * secure communication sessions between two peers.  <code>SSLEngine</code>
 * operations typically consume bytes from an input buffer and produce
 * bytes in an output buffer.  This class provides operational result
 * values describing the state of the <code>SSLEngine</code>, including
 * indications of what operations are needed to finish an
 * ongoing handshake.  Lastly, it reports the number of bytes consumed
 * and produced as a result of this operation.
 *
 * @see SSLEngine
 * @see SSLEngine#wrap(ByteBuffer, ByteBuffer)
 * @see SSLEngine#unwrap(ByteBuffer, ByteBuffer)
 *
 * @author Brad R. Wetmore
 * @since 1.5
 */

class SSLEngineResult {

    /**
     * An <code>SSLEngineResult</code> enum describing the overall result
     * of the <code>SSLEngine</code> operation.
     *
     * The <code>Status</code> value does not reflect the
     * state of a <code>SSLEngine</code> handshake currently
     * in progress.  The <code>SSLEngineResult's HandshakeStatus</code>
     * should be consulted for that information.
     *
     * @author Brad R. Wetmore
     * @since 1.5
     */
    static enum Status {

        /**
         * The <code>SSLEngine</code> was not able to unwrap the
         * incoming data because there were not enough source bytes
         * available to make a complete packet.
         *
         * <P>
         * Repeat the call once more bytes are available.
         */
        BUFFER_UNDERFLOW,

        /**
         * The <code>SSLEngine</code> was not able to process the
         * operation because there are not enough bytes available in the
         * destination buffer to hold the result.
         * <P>
         * Repeat the call once more bytes are available.
         *
         * @see SSLSession#getPacketBufferSize()
         * @see SSLSession#getApplicationBufferSize()
         */
        BUFFER_OVERFLOW,

        /**
         * The <code>SSLEngine</code> completed the operation, and
         * is available to process similar calls.
         */
        OK,

        /**
         * The operation just closed this side of the
         * <code>SSLEngine</code>, or the operation
         * could not be completed because it was already closed.
         */
        CLOSED
    }

    


    private Status status;
    private HandshakeStatus handshakeStatus;
    private int _bytesConsumed;
    private int _bytesProduced;

    /**
     * Initializes a new instance of this class.
     *
     * @param   status
     *          the return value of the operation.
     *
     * @param   handshakeStatus
     *          the current handshaking status.
     *
     * @param   bytesConsumed
     *          the number of bytes consumed from the source ByteBuffer
     *
     * @param   bytesProduced
     *          the number of bytes placed into the destination ByteBuffer
     *
     * @throws  IllegalArgumentException
     *          if the <code>status</code> or <code>handshakeStatus</code>
     *          arguments are null, or if <code>bytesConsumed</code> or
     *          <code>bytesProduced</code> is negative.
     */
    this(Status status, HandshakeStatus handshakeStatus,
            int bytesConsumed, int bytesProduced) {

        if ((bytesConsumed < 0) || (bytesProduced < 0)) {
            throw new IllegalArgumentException("Invalid Parameter(s)");
        }

        this.status = status;
        this.handshakeStatus = handshakeStatus;
        this._bytesConsumed = bytesConsumed;
        this._bytesProduced = bytesProduced;
    }

    /**
     * Gets the return value of this <code>SSLEngine</code> operation.
     *
     * @return  the return value
     */
    Status getStatus() {
        return status;
    }

    /**
     * Gets the handshake status of this <code>SSLEngine</code>
     * operation.
     *
     * @return  the handshake status
     */
    HandshakeStatus getHandshakeStatus() {
        return handshakeStatus;
    }

    /**
     * Returns the number of bytes consumed from the input buffer.
     *
     * @return  the number of bytes consumed.
     */
    int bytesConsumed() {
        return _bytesConsumed;
    }

    /**
     * Returns the number of bytes written to the output buffer.
     *
     * @return  the number of bytes produced
     */
    int bytesProduced() {
        return _bytesProduced;
    }

    /**
     * Returns a string representation of this object.
     */
    override
    string toString() {
        return ("Status = " ~ status.to!string() ~
            " HandshakeStatus = " ~ handshakeStatus.to!string() ~
            "\nbytesConsumed = " ~ _bytesConsumed.to!string() ~
            " bytesProduced = " ~ _bytesProduced.to!string());
    }
}
