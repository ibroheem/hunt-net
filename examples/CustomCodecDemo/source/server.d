module server;

import hunt.net;
import hunt.logging;

import hunt.net.codec.textline;

import std.format;

void main() {

    NetServerOptions options = new NetServerOptions();
    NetServer server = NetUtil.createNetServer!(ThreadMode.Single)(options);

    server.setCodec(new TextLineCodec);

    server.setHandler(new class ConnectionEventHandler {

        override void connectionOpened(Connection connection) {
            infof("Connection created: %s", connection.getRemoteAddress());
        }

        override void connectionClosed(Connection connection) {
            infof("Connection closed: %s", connection.getRemoteAddress());
        }

        override void messageReceived(Connection connection, Object message) {
            tracef("message type: %s", typeid(message).name);
            string str = format("data received: %s", message.toString());
            tracef(str);
            connection.write(str);
        }

        override void exceptionCaught(Connection connection, Throwable t) {
            warning(t);
        }

        override void failedOpeningConnection(int connectionId, Throwable t) {
            warning(t);
        }

        override void failedAcceptingConnection(int connectionId, Throwable t) {
            warning(t);
        }
    }).listen("0.0.0.0", 8080);
}
