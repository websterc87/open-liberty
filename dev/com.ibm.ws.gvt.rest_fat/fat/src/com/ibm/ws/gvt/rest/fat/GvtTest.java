/*******************************************************************************
 * Copyright (c)  2024 IBM Corporation and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License 2.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-2.0/
 *
 * SPDX-License-Identifier: EPL-2.0
 *
 * Contributors:
 *     IBM Corporation - initial API and implementation
 *******************************************************************************/
package com.ibm.ws.gvt.rest.fat;

import static org.junit.Assert.assertEquals;

import org.apache.http.HttpStatus;
import org.apache.http.client.methods.CloseableHttpResponse;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;

import componenttest.annotation.Server;
import componenttest.custom.junit.runner.FATRunner;
import componenttest.custom.junit.runner.Mode;
import componenttest.custom.junit.runner.Mode.TestMode;
import componenttest.topology.impl.LibertyServer;

@RunWith(FATRunner.class)
@Mode(TestMode.LITE)
public class GvtTest extends BaseTestCase {

    private static final String ENDPOINT_NOTIFICATION = "/IBMJMXConnectorREST/notifications";
    private static final String ENDPOINT_MBEAN = "/IBMJMXConnectorREST/mbeans";
    private static final String DELIVERY_INTERVAL = "{\"deliveryInterval\": \"\\u0036\\u0030\\u0030\\u0030\\u0030\"}";
    private static final String CLASS_NAME = "{\"className\": \"\\u0063\\u006f\\u006d\\u002e\\u0069\\u0062\\u006d\\u002e\\u0076\\u0069\\u0072\\u0074\\u0075\\u0061\\u006c\\u0069\\u007a\\u0061\\u0074\\u0069\\u006f\\u006e\\u002e\\u006d\\u0061\\u006e\\u0061\\u0067\\u0065\\u006d\\u0065\\u006e\\u0074\\u002e\\u0069\\u006e\\u0074\\u0065\\u0072\\u006e\\u0061\\u006c\\u002e\\u0047\\u0075\\u0065\\u0073\\u0074\\u004f\\u0053\"}";

    @Server("com.ibm.gvt.server")
    public static LibertyServer server;
    private CloseableHttpResponse unicode;

    @Before
    public void before() throws Exception {
        server.startServer();
        waitForDefaultHttpsEndpoint(server);
    }

    @After
    public void after() throws Exception {

        stopServer(server);
    }

    /**
     * GVT for Unicode compliance of JMXConnector REST api - Create Notification Registry.
     *
     * @throws Exception if there was an unforeseen error getting the certificates.
     */
    @Test
    public void testUnicodeForNotification() throws Exception {

        unicode = HttpUtils.performPostGvt(server, ENDPOINT_NOTIFICATION, 200, "application/json", USER1_NAME, USER1_PASSWORD,
                                           "application/json",
                                           DELIVERY_INTERVAL);

        assertEquals("Unexpected status code response", HttpStatus.SC_OK, unicode.getStatusLine().getStatusCode());

    }

    /**
     * GVT for Unicode compliance of JMXConnector REST api - Retrieves list of MBeans by filtered Query Expression.
     *
     * @throws Exception if there was an unforeseen error getting the certificates.
     */
    @Test
    public void testUnicodeForMbeans() throws Exception {

        unicode = HttpUtils.performPostGvt(server, ENDPOINT_MBEAN, 200, "application/json", USER1_NAME, USER1_PASSWORD,
                                           "application/json",
                                           CLASS_NAME);
        assertEquals("Unexpected status code response", HttpStatus.SC_OK, unicode.getStatusLine().getStatusCode());

    }
}
