module hunt.net.secure.conscrypt.AbstractConscryptSSLContextFactory;

// dfmt off
version(WITH_HUNT_SECURITY):
// dfmt on

import hunt.net.secure.ProtocolSelector;
import hunt.net.secure.conscrypt.ConscryptALPNSelector;
import hunt.net.secure.SSLContextFactory;
import hunt.net.ssl;
import hunt.security.cert.X509Certificate;

import hunt.io.ByteArrayInputStream;
import hunt.io.Common;

import hunt.Exceptions;
import hunt.util.DateTime;
import hunt.util.TypeUtils;

import hunt.logging;

import std.array;
import std.datetime : Clock;
import std.datetime.stopwatch;
import std.typecons;


/**
*/
abstract class AbstractConscryptSSLContextFactory : SSLContextFactory {

    private enum string provideName = "Conscrypt";
    private string[] supportedProtocols;

    // static this() {
    //     // Provider provider = Conscrypt.newProvider();
    //     // provideName = provider.getName();
    //     // Security.addProvider(provider);
    //     // provideName = "Conscrypt";
    //     infof("add Conscrypt security provider");
    // }

    static string getProvideName() {
        return provideName;
    }

    SSLContext getSSLContextWithManager(KeyManager[] km, TrustManager[] tm){
        version(HUNT_NET_DEBUG) long start = Clock.currStdTime;

        SSLContext sslContext = SSLContext.getInstance("TLSv1.2", provideName);
        sslContext.init(km, tm);

        version(HUNT_NET_DEBUG) {
            long end = Clock.currStdTime;
            long d = convert!(TimeUnit.HectoNanosecond, TimeUnit.Millisecond)(end - start);
            tracef("creating Conscrypt SSL context spends %d ms", d);
        }
        return sslContext;
    }

    SSLContext getSSLContext(InputStream inputStream, string keystorePassword, string keyPassword) {
        return getSSLContext(inputStream, keystorePassword, keyPassword, null, null, null);
    }

    SSLContext getSSLContext(InputStream inputStream, string keystorePassword, string keyPassword,
                                    string keyManagerFactoryType, string trustManagerFactoryType, string sslProtocol) {
        version(HUNT_NET_DEBUG) StopWatch sw = StopWatch(AutoStart.yes);
        SSLContext sslContext;

        // KeyStore ks = KeyStore.getInstance("JKS");
        // ks.load(inputStream, keystorePassword !is null ? keystorePassword.toCharArray() : null);

        // // PKIX,SunX509
        // KeyManagerFactory kmf = KeyManagerFactory.getInstance(keyManagerFactoryType == null ? "SunX509" : keyManagerFactoryType);
        // kmf.init(ks, keyPassword !is null ? keyPassword.toCharArray() : null);

        // TrustManagerFactory tmf = TrustManagerFactory.getInstance(trustManagerFactoryType == null ? "SunX509" : trustManagerFactoryType);
        // tmf.init(ks);

        // TLSv1 TLSv1.2
        sslContext = SSLContext.getInstance(sslProtocol.empty ? "TLSv1.2" : sslProtocol, provideName);
        // sslContext.init(kmf.getKeyManagers(), tmf.getTrustManagers(), null);

        version(HUNT_NET_DEBUG) {
            sw.stop();
            infof("creating Conscrypt SSL context spends %s ms", sw.peek.total!"msecs");
        }

        implementationMissing(false);
        return sslContext;
    }

    SSLContext getSSLContext(string certificate, string privatekey, string keystorePassword, string keyPassword,
                                    string keyManagerFactoryType, string trustManagerFactoryType, string sslProtocol) {
        version(HUNT_NET_DEBUG) StopWatch sw = StopWatch(AutoStart.yes);
        SSLContext sslContext;

        // // PKIX,SunX509
        // KeyManagerFactory kmf = KeyManagerFactory.getInstance(keyManagerFactoryType == null ? "SunX509" : keyManagerFactoryType);
        // kmf.init(ks, keyPassword !is null ? keyPassword.toCharArray() : null);

        // TrustManagerFactory tmf = TrustManagerFactory.getInstance(trustManagerFactoryType == null ? "SunX509" : trustManagerFactoryType);
        // tmf.init(ks);

        // TLSv1 TLSv1.2
        sslContext = SSLContext.getInstance(certificate, privatekey, sslProtocol.empty ? "TLSv1.2" : sslProtocol, provideName);
        // sslContext.init(kmf.getKeyManagers(), tmf.getTrustManagers(), null);

        version(HUNT_NET_DEBUG) {
            infof("creating Conscrypt SSL context spends %s ms", sw.peek.total!"msecs");
            sw.stop();
        }

        // implementationMissing(false);
        return sslContext;
    }

    SSLContext getSSLContext() {
        throw new NotImplementedException();
    }

    // SSLContext getSSLContext(string certificate, string privatekey, 
    //     string keystorePassword, string keyPassword) {
    //         throw new NotImplementedException();
    //     }

    Pair!(SSLEngine, ProtocolSelector) createSSLEngine(bool clientMode) {
        SSLEngine sslEngine = getSSLContext().createSSLEngine(clientMode);
        // sslEngine.setUseClientMode(clientMode);
        return makePair(sslEngine, cast(ProtocolSelector)new ConscryptALPNSelector(sslEngine, supportedProtocols));
    }

    // Pair!(SSLEngine, ProtocolSelector) createSSLEngine(string certificate, string privatekey, 
    //     string keystorePassword, string keyPassword) {
    //     SSLEngine sslEngine = getSSLContext(certificate, privatekey,
    //          keystorePassword, keyPassword).createSSLEngine();
    //     sslEngine.setUseClientMode(false);
    //     return makePair(sslEngine, cast(ProtocolSelector)new ConscryptALPNSelector(sslEngine, supportedProtocols));
    // }

    Pair!(SSLEngine, ProtocolSelector) createSSLEngine(bool clientMode, string peerHost, int peerPort) {
        SSLEngine sslEngine = getSSLContext().createSSLEngine(clientMode, peerHost, peerPort);
        // sslEngine.setUseClientMode(clientMode);
        return makePair(sslEngine, cast(ProtocolSelector)new ConscryptALPNSelector(sslEngine, supportedProtocols));
    }

    string[] getSupportedProtocols() {
        return supportedProtocols;
    }

    void setSupportedProtocols(string[] supportedProtocols) {
        this.supportedProtocols = supportedProtocols;
    }
}


/**
*/
class NoCheckConscryptSSLContextFactory : AbstractConscryptSSLContextFactory {


    static X509TrustManager createX509TrustManagerNoCheck() {
        return new class X509TrustManager {
            override void checkClientTrusted(X509Certificate[] chain, string authType) {
            }

            override void checkServerTrusted(X509Certificate[] chain, string authType){
            }

            override X509Certificate[] getAcceptedIssuers() {
                return null;
            }
        };
    }

    override SSLContext getSSLContext() {
        try {
            return getSSLContextWithManager(null, [createX509TrustManagerNoCheck()]);
        } catch (Exception e) {
            errorf("get SSL context error: %s", e.msg);
            return null;
        }
    }
}


/**
*/
class DefaultCredentialConscryptSSLContextFactory : AbstractConscryptSSLContextFactory {

    enum byte[] DEFAULT_CREDENTIAL = [-2, -19, -2, -19, 0, 0, 0, 2, 0, 0, 0, 1, 0, 0, 0, 1, 0, 13, 102, 105, 114, 
    101, 102, 108, 121, 115, 111, 117, 114, 99, 101, 0, 0, 1, 61, 118, 20, 75, -72, 0, 0, 5, 2, 48, -126, 4, -2, 48, 14, 6, 
    10, 43, 6, 1, 4, 1, 42, 2, 17, 1, 1, 5, 0, 4, -126, 4, -22, -40, -117, -90, 24, 90, 34, 67, 84, 83, 67, 123, 105, 66, 
    75, 57, -41, -111, -65, -27, 59, -46, -125, -71, -47, -60, 45, -101, -94, -8, 53, 114, 1, 43, 49, -88, 89, -57, 110, 20,
    -114, -51, 103, -88, -127, 19, 9, 111, 127, -43, -102, 114, 27, 126, 61, 14, 120, -116, 50, -44, 79, -62, -71, -88, 46, 
    -118, 110, -67, -42, -73, -123, 2, -108, -123, 1, 100, 22, -3, -1, 118, -128, -77, 47, 61, 30, -38, -23, 49, 105, 115, 
    -118, -55, 85, 14, 80, -94, -51, 79, 58, -90, -43, -2, -50, 121, -27, -73, 4, 10, 95, -64, -50, -73, -74, 94, -37, -65, 
    15, -32, -101, 8, 62, -48, 18, -76, 86, -38, -82, 34, -124, -4, 84, 113, 105, -96, -82, -45, -68, 116, -1, -86, -58, 
    119, -73, -28, 12, 81, 94, 91, -6, 6, 120, -17, 41, 16, -111, -103, -114, 61, 0, -3, -45, -46, -78, 12, -72, 124, -41, 
    -18, 117, 52, 123, -73, 0, -22, 34, -76, -43, 49, 95, -9, -59, 51, -128, -45, -34, 100, -19, -112, 45, -74, 106, 88, 94, 
    7, 19, 65, -36, 73, 3, 119, 21, 72, 23, -13, -68, 102, -84, -2, 82, -113, -13, -116, 66, -70, 21, 23, 106, 39, 110, 114, 
    -92, 119, 113, -38, -23, 33, -29, 79, -73, 96, 122, 24, 89, -8, 97, -13, 108, 77, 94, 87, -33, 8, 3, 51, -80, 29, -29, 
    -102, -49, 83, -58, -84, 1, 47, -5, -102, 93, 29, 15, -85, 80, 92, 96, 60, -2, 66, 110, 4, 83, 94, 39, -74, 76, 0, -126, 
    -29, -75, 77, 66, -94, 92, 48, -25, 38, 55, -94, 11, 79, 4, 8, 100, 103, 73, -50, 82, 63, 20, 11, 25, -73, -39, -73, 26, 
    -91, 101, -35, 119, 79, 82, 98, 118, 32, 18, 73, -19, 22, 121, 124, 98, -99, -124, 21, -88, -38, 33, 74, 69, 108, -73, 
    -61, -5, -43, -69, 30, -17, 41, 106, 64, -89, 36, -29, 4, 34, 85, 95, 121, 50, 112, -64, -82, 112, 22, 118, 93, -87, 90, 
    73, -24, 114, -56, 106, 97, 66, 22, 92, -21, -44, 61, -86, -122, 80, 15, -78, 71, 2, -79, -35, 90, 78, -119, -74, -59, 
    85, -70, 95, -106, -12, -119, 53, -101, 85, 30, -69, 64, 93, -55, 2, -101, 118, -111, 86, -14, 72, 112, -94, -128, 94, 
    -112, -72, -90, -23, 111, 10, 120, -15, 16, 2, -127, -74, -45, -9, 69, 55, 82, 17, -34, -60, -36, 118, -82, -98, -22, 
    -13, 95, 117, -87, -102, 126, 98, -45, 98, 56, 94, -92, 111, 88, 0, 127, 67, 53, -5, -98, 57, -123, -126, 117, 97, -114, 
    -19, -102, 57, -7, 82, 76, 119, 44, 93, -112, -119, -52, 32, -106, -52, -58, 0, -52, 97, -16, -11, -15, -73, 2, 87, 122, 
    95, 125, 66, 92, -41, -4, -79, -56, 52, -106, -44, 0, -16, -51, 98, -119, 15, 44, -42, -107, 86, -68, -124, 17, -33, 
    -105, -59, 50, 97, -115, 54, 70, 113, 50, -27, 121, -5, 42, -38, -61, -96, -96, -96, -97, 58, 19, -53, 96, 102, -7, 116, 
    64, -14, -81, 94, 74, -71, 115, 9, 51, 95, 63, 55, -110, -21, -106, 112, -19, 18, -43, 41, 68, -52, 88, 48, 26, 57, 17, 
    -107, -121, -52, -8, 37, 108, 29, -73, 16, 69, 34, -48, 112, -57, -30, 27, -64, 89, -54, 26, -112, -71, -24, -121, 112, 
    45, -93, 4, 50, 47, 83, 124, -58, -16, -16, -46, 87, 39, -40, -24, 48, 33, -38, 24, -20, -64, -12, 94, -31, 38, 0, 22, 
    107, 47, 43, 97, 63, -111, -124, 71, 92, 78, -113, -48, -26, 10, -3, 34, -21, -98, -59, 17, -44, -82, -124, 37, -98, -83, 
    -101, 5, -52, 95, -85, -25, -67, 83, -46, 9, 82, 48, 16, -119, 95, 90, -54, -16, -123, -47, 70, -12, -56, -31, -16, -55, 
    38, 23, -69, -90, 29, -88, -21, 29, 83, 63, -101, -109, -45, 118, 95, 117, -10, 45, -1, -9, 6, 44, -65, -48, 118, 86, 103, 
    64, 105, 3, 15, 67, -115, -15, -33, 20, -62, 103, 38, 104, -128, 27, 35, -39, 44, 13, -49, 94, 58, -48, 21, -14, -94, -18, 
    107, 68, -39, -64, 17, 66, 18, -80, 53, -80, -106, 96, -10, -67, 115, 56, 99, -77, 124, 75, 66, -26, -10, 121, 8, 108, 
    -91, -29, 121, 67, 114, -48, -56, 26, 111, 56, 11, 123, -3, 8, 31, 113, -106, 21, 34, 65, 10, -2, -55, -77, -47, -111, 70, 
    -61, -38, 36, -119, 42, -49, 125, 45, 63, -45, 84, -20, -10, -38, -102, 87, 78, 61, 79, 40, -60, -84, 111, -69, 41, -51, 
    119, -20, -84, 6, 49, -46, 124, 52, 52, -57, 18, -89, 91, 92, -114, -76, -117, -76, 58, -73, 16, 72, -66, 84, 56, 57, 63, 
    63, -73, -47, -69, 105, -79, -66, 33, -57, -82, -64, 3, -85, -16, 26, -88, 62, -19, -67, 49, -9, -36, -52, -16, 48, -10, 
    -125, -80, 99, -94, -51, -96, 54, -72, 20, 21, -23, 49, -102, 77, -55, -121, -76, 78, 67, 58, 48, 7, 12, 45, -23, -87, 
    -125, -95, -77, 54, -12, -5, -44, -57, -44, -115, -62, -104, -66, 2, -15, -87, -35, -62, -76, -113, 72, 77, 29, -100, 111, 
    -94, -112, -73, -71, 59, 119, -84, -26, 100, -4, 125, 62, 19, 125, 5, 107, -24, -88, 63, 31, 58, -63, -16, -49, -30, -97, 
    111, -111, 9, -22, 119, -20, 25, 44, 123, 85, 28, 83, -101, -11, 18, -75, 80, -74, -63, 73, -84, 91, 86, 79, 115, -4, 83, 
    -67, -126, 76, -87, 105, 66, -45, -62, -100, -53, -51, -96, -28, 60, 7, -93, -59, -22, 2, 96, -77, -42, -110, 79, -98, 120, 
    83, 122, 23, -9, -57, -88, -31, 40, -83, -121, -62, -96, 46, 54, -27, -103, -26, 15, 94, -69, -13, 21, -37, 114, -45, -51, 
    58, -31, 117, 76, 21, -51, -57, 13, 111, 51, 6, -15, 6, 69, -22, -70, 56, -108, 84, -108, -83, -26, 70, 73, 116, -70, -72, 
    63, 38, 95, 61, -125, -41, -23, -97, -89, 76, 110, -89, 90, 29, -41, 104, -105, -17, 92, 43, -1, -64, 21, -89, -73, 17, 9, 
    -77, 32, 59, 12, 4, 17, 44, -124, -41, -104, -45, 54, -6, 27, -56, 17, 126, -34, -80, -115, -62, -46, 61, 46, -95, -57, 126, 
    -100, 36, -50, -17, 21, 7, 30, -10, 25, 98, 95, -127, -17, 89, -91, -37, 108, 76, 68, -31, 36, 105, -128, 31, 119, 102, 
    -85, 103, -60, 74, -91, 105, -16, -35, 63, 81, 8, -36, -94, -24, -26, -52, -109, -23, 49, 43, 72, -112, -34, 26, 38, 93, 2, 
    57, 113, 35, -121, 1, -13, 77, 112, -70, -73, -2, -82, 125, -72, -50, 85, 18, 86, -126, 72, 25, -110, -31, 80, 56, 83, -86, 
    126, 52, -97, -40, -89, 59, -102, -26, 44, 116, 16, -121, 51, -102, 30, -100, -98, 105, -102, -18, 62, -65, 84, -105, 105, 
    -51, -121, -5, -70, -126, 83, 36, -53, 124, -111, 11, 5, 31, 8, -59, 3, -126, -24, 21, -71, -20, 9, 116, -58, 20, 27, 69, 
    11, 9, 49, 52, -79, 69, -121, -22, -49, 43, -46, -94, 56, -31, -106, -104, -32, -78, -122, 7, -4, -118, -114, 66, -90, -32, 
    97, 61, -16, -9, 38, -37, 1, 97, 95, -54, 106, -87, 0, 0, 0, 1, 0, 5, 88, 46, 53, 48, 57, 0, 0, 3, -125, 48, -126, 3, 127, 
    48, -126, 2, 103, -96, 3, 2, 1, 2, 2, 4, 9, -42, -108, -71, 48, 13, 6, 9, 42, -122, 72, -122, -9, 13, 1, 1, 11, 5, 0, 48, 
    112, 49, 11, 48, 9, 6, 3, 85, 4, 6, 19, 2, 67, 78, 49, 14, 48, 12, 6, 3, 85, 4, 8, 19, 5, 72, 117, 98, 101, 105, 49, 14, 
    48, 12, 6, 3, 85, 4, 7, 19, 5, 87, 117, 104, 97, 110, 49, 16, 48, 14, 6, 3, 85, 4, 10, 19, 7, 102, 105, 114, 101, 102, 108, 
    121, 49, 26, 48, 24, 6, 3, 85, 4, 11, 19, 17, 102, 105, 114, 101, 102, 108, 121, 115, 111, 117, 114, 99, 101, 46, 99, 111, 
    109, 49, 19, 48, 17, 6, 3, 85, 4, 3, 19, 10, 83, 116, 101, 118, 101, 110, 32, 81, 105, 117, 48, 30, 23, 13, 49, 51, 48, 51, 
    49, 55, 48, 50, 48, 49, 49, 52, 90, 23, 13, 49, 51, 48, 54, 49, 53, 48, 50, 48, 49, 49, 52, 90, 48, 112, 49, 11, 48, 9, 6, 
    3, 85, 4, 6, 19, 2, 67, 78, 49, 14, 48, 12, 6, 3, 85, 4, 8, 19, 5, 72, 117, 98, 101, 105, 49, 14, 48, 12, 6, 3, 85, 4, 7, 
    19, 5, 87, 117, 104, 97, 110, 49, 16, 48, 14, 6, 3, 85, 4, 10, 19, 7, 102, 105, 114, 101, 102, 108, 121, 49, 26, 48, 24, 
    6, 3, 85, 4, 11, 19, 17, 102, 105, 114, 101, 102, 108, 121, 115, 111, 117, 114, 99, 101, 46, 99, 111, 109, 49, 19, 48, 17, 
    6, 3, 85, 4, 3, 19, 10, 83, 116, 101, 118, 101, 110, 32, 81, 105, 117, 48, -126, 1, 34, 48, 13, 6, 9, 42, -122, 72, -122, 
    -9, 13, 1, 1, 1, 5, 0, 3, -126, 1, 15, 0, 48, -126, 1, 10, 2, -126, 1, 1, 0, -124, 6, 13, 96, 125, -100, 33, -127, 120, 
    -93, 118, -26, -97, 97, 65, 51, -29, -46, -23, 29, -81, 124, 85, -99, -101, 15, 97, -63, -75, 7, 119, -100, 127, 0, -17, 
    123, 16, 14, 58, -64, 124, 84, -122, 9, 84, -29, -47, -46, 47, 60, -52, -65, 4, 91, 111, 54, -51, -117, -108, 22, -59, 12,
    62, -91, 111, 64, -32, 57, 89, -104, -11, 84, 85, 75, -109, -96, -83, -32, 72, -18, -13, -48, 59, 18, 125, -75, -36, 46, 
    -51, 54, -66, -121, -79, 91, -64, -49, -101, -21, 34, 36, 55, -85, -96, 8, 81, -19, -22, 96, 74, 53, -94, -1, 123, 24, -53, 
    -57, 80, -78, -122, -23, -116, -23, -53, 103, -48, -85, -117, 6, -96, 119, 55, -30, 53, 1, -32, 23, 36, 50, -82, -81, 88, 
    -62, -26, -112, -41, 88, -79, 53, 98, -26, 81, 2, -9, 5, 92, 30, -87, 87, 80, 89, 19, 93, 37, 20, -113, 39, 2, -52, 62, 
    -16, 62, 120, 43, 58, 38, -8, -1, -128, -37, 20, -58, 112, -82, 55, 10, 42, -49, 126, 111, -44, -99, 127, 57, -93, -85, 
    -47, -25, -121, 50, -48, 12, 84, -100, -14, 20, 84, -110, -2, -44, -80, -59, -96, 58, -39, -56, 0, 127, -47, -73, -74, 
    13, 94, -42, -14, 48, 57, -100, 16, 15, 76, -88, 68, 97, 99, -76, -114, 44, 2, -116, -102, -59, -109, -39, 25, -120, 34, 
    -36, -11, -93, 7, -23, -43, 32, 58, -26, -111, 2, 3, 1, 0, 1, -93, 33, 48, 31, 48, 29, 6, 3, 85, 29, 14, 4, 22, 4, 20, 53, 
    -37, 31, -44, -128, 35, -118, -23, -8, -37, -126, -127, 121, -71, 30, 12, 80, -121, 68, -125, 48, 13, 6, 9, 42, -122, 72, 
    -122, -9, 13, 1, 1, 11, 5, 0, 3, -126, 1, 1, 0, 102, -9, -109, 109, -12, 92, -92, 112, 3, 105, 68, -32, -104, 125, 29, -72, 
    113, 4, 52, 78, 4, -78, -57, -90, -84, -37, 67, 120, -6, 64, -6, -28, 20, -44, 101, -111, 110, 74, 92, -117, 92, -73, 65, 
    3, 13, -44, -22, 95, -7, 1, -85, -84, -54, -93, 30, 91, 127, 8, -47, -116, -30, -72, -55, 11, -123, 100, -54, 9, -105, 7, 
    -10, 2, 62, 1, -29, 106, 99, -121, -24, -44, 94, -44, 124, 28, -95, 90, -46, -66, -1, 84, 63, 27, -126, 64, 11, 47, 84, 
    -36, -92, 102, 8, -54, -47, 34, -122, 88, -105, 113, 86, 41, 53, 120, 31, 59, 116, 105, -94, 95, 2, -103, 96, -35, -53, 
    85, -109, -28, -24, -14, -72, -122, 10, -92, 61, 121, -114, -31, 93, 122, -58, -12, -82, -115, 60, -111, -128, 88, 5, 113, 
    -74, -2, -124, -60, -80, 4, -1, 119, -128, -23, -123, -54, 22, -89, 27, -83, -20, 46, 44, 97, 42, 97, 21, -119, -97, -113, 
    13, -91, -4, -43, -95, -112, 4, -101, -122, -128, -71, -16, 41, -96, -126, 64, 71, -3, 46, 98, -19, 1, -106, 36, 39, -116, 
    87, -7, 110, -86, 67, -75, -62, 121, -32, 8, 27, -54, -86, 119, -109, 66, 91, 48, 117, -38, -97, 90, 72, 103, -61, -26, 
    -16, 20, -117, 2, 98, -40, 29, -79, -35, -53, 74, -84, -101, -69, 86, -36, 15, 2, 91, -111, -9, -38, -5, 11, -66, 11, 117, 
    -83, 50, -91, -34, -55, -59, 57, 86, -39, 14, 80, 21, -102, 56, 45, -79, 3, -54, 12, -118, -13, 1, -55 ];

    override SSLContext getSSLContext() {
        try {
            return getSSLContext(new ByteArrayInputStream(DEFAULT_CREDENTIAL), "ptmima1234", "ptmima4321");
        } catch (Exception e) {
            errorf("get SSL context error", e);
            return null;
        }
    }

    alias getSSLContext = AbstractConscryptSSLContextFactory.getSSLContext;
}

/**
*/
class FileCredentialConscryptSSLContextFactory : AbstractConscryptSSLContextFactory {

    private string certificate;
    private string privatekey;
    private string keystorePassword;
    private string keyPassword;

    this(string certificate, string privatekey, 
        string keystorePassword, string keyPassword) {
            this.certificate = certificate; 
            this.privatekey = privatekey;
        }

    override SSLContext getSSLContext() {
        try {
            return getSSLContext(certificate, privatekey, keystorePassword, keyPassword, null, null, null);
        } catch (Exception e) {
            errorf("get SSL context error", e);
            return null;
        }
    }

    alias getSSLContext = AbstractConscryptSSLContextFactory.getSSLContext;
}
