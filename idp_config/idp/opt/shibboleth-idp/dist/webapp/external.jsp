<%@ page pageEncoding="UTF-8" %>
<%@ page import="net.shibboleth.idp.authn.*" %>
<%@ page import="net.shibboleth.idp.attribute.*"%>
<%@ page import="net.shibboleth.idp.authn.principal.*"%>
<%@ page import="net.shibboleth.idp.saml.authn.principal.*"%>
<%@ page import="java.security.*"%>
<%@ page import="javax.security.auth.*"%>
<%@ page import="java.util.*"%>
<%@ page import="java.net.http.*"%>
<%@ page import="com.fasterxml.jackson.databind.ObjectMapper"%>
<%@ page import="com.fasterxml.jackson.databind.JsonNode"%>
<%@ page import="org.springframework.context.ApplicationContext"%>
<%@ page import="org.springframework.web.servlet.support.RequestContextUtils"%>
<%@ page import="org.springframework.core.env.Environment"%>
<%@ page import="javax.servlet.http.Cookie"%>

<%!
final org.slf4j.Logger logger = org.slf4j.LoggerFactory.getLogger("external_auth");

// Try to validate a domino session. If callback_key != null, this validation is
// being processed by the callback from domino after an explicit authentication redirect.
// Otherwise, redirect_key != null, and we found a potential existing domino session
// we are going to try and validate without having to redirect the user to domino.
private String validate_session(Environment environment, HttpServletRequest request,
				HttpServletResponse response, String callback_key, String redirect_key)
				throws ExternalAuthenticationException, java.io.IOException {

	final String cookie_header = request.getHeader("Cookie");
	logger.debug("request cookies = " + cookie_header);

	final HttpClient http_client = HttpClient.newHttpClient();

	// This assumes domino is running on same server on standard ports
	final String validate_url = request.getScheme() + "://" +
					request.getServerName() + "/idpproxy.nsf/validate";
	logger.debug("validation URL = " + validate_url);

	// We send the domino validation page the same cookies we received, which will
	// include any necessary domino session state
	final HttpRequest validate_request = HttpRequest.newBuilder()
			.uri(java.net.URI.create(validate_url))
			.header("Cookie", cookie_header)
			.timeout(java.time.Duration.ofSeconds(10))
			.GET()
			.build();

	HttpResponse<String> validate_response = null;
	try {
		validate_response = http_client.send(validate_request,
					java.net.http.HttpResponse.BodyHandlers.ofString());
	}
	catch (final Exception e) {
		logger.error("domino validation call failed, exception = " + e);
		return "domino validation call failed";
	}

	if (validate_response.statusCode() != 200) {
		logger.error("domino validation call failed, status = " + validate_response.statusCode());
		return "domino validation call failed";
	}

	final String body = validate_response.body();
	logger.debug("response body = " + body);

	final ObjectMapper mapper = new ObjectMapper();

	JsonNode jsonRoot = null;
	try {
		jsonRoot = mapper.readTree(body);
	}
	catch (com.fasterxml.jackson.core.JsonParseException e) {
		logger.error("json parse failed - " + e.toString());
		logger.error("response body = " + body);
		return "invalid domino response";
	}
	catch (com.fasterxml.jackson.core.JsonProcessingException e) {
		logger.error("json processing failed - " + e.toString());
		logger.error("response body = " + body);
		return "invalid domino response";
	}

	final JsonNode statusNode = jsonRoot.get("status");
	if (statusNode == null) {
		logger.error("domino response status not found");
		logger.error("response body = " + body);
		return "invalid domino response";
	}
	else if (!statusNode.isNumber()) {
		logger.error("domino response status not numeric");
		logger.error("response body = " + body);
		return "invalid domino response";
	}
	else if (statusNode.intValue() != 1) {
		// We only log this as an error if we are processing the redirect callback. Otherwise,
		// it might have been a stale domino session and we just need to send the user to
		// domino again for a fresh authentication
		if (callback_key != null) {
			logger.error("domino response status not successful - " + statusNode.intValue());
		}
		else {
			logger.debug("domino response status (pre redirect) not successful - " +
							statusNode.intValue());
		}
		return "domino validation failed";
	}

	boolean mfa = false;
	final JsonNode mfaNode = jsonRoot.get("mfa");
	if (mfaNode != null && mfaNode.isNumber() && mfaNode.intValue() == 1) {
		mfa = true;
	}

	final JsonNode usernameNode = jsonRoot.get("username");
	if (usernameNode == null) {
		logger.error("domino response username not found");
		logger.error("response body = " + body);
		return "invalid domino response";
	}
	else if (!usernameNode.isTextual()) {
		logger.error("domino response username not string");
		logger.error("response body = " + body);
		return "invalid domino response";
	}
	else if (usernameNode.textValue().isEmpty()){
		logger.error("domino response username empty");
		return "invalid domino response";
	}

	final HashSet<Principal> principals=new HashSet<Principal>();
	principals.add(new UsernamePrincipal(usernameNode.textValue()));

	final JsonNode attributesNode = jsonRoot.get("attributes");
	if (attributesNode == null) {
		logger.error("domino response attributes not found");
		logger.error("response body = " + body);
		return "invalid domino response";
	}
	else if (!attributesNode.isObject()) {
		logger.error("domino response attributes not object");
		logger.error("response body = " + body);
		return "invalid domino response";
	}

	final Iterator<Map.Entry<String, JsonNode>> fields = attributesNode.fields();
	while (fields.hasNext()) {
		final Map.Entry<String, JsonNode> jsonField = fields.next();
		final ArrayList<IdPAttributeValue> attr_values = new ArrayList<IdPAttributeValue>();
		final String jsonKey = jsonField.getKey();
		final JsonNode jsonValue = jsonField.getValue();

		if (jsonValue.isArray()) {
			for (JsonNode arrayNode : jsonValue) {
				if (arrayNode.isTextual()) {
					attr_values.add(new StringAttributeValue(arrayNode.textValue()));
				}
				else {
					logger.error("domino response attribute " + jsonKey + " array value not string");
					logger.error("response body = " + body);
					return "invalid domino response";
				}
			}
		}
		else if (jsonValue.isTextual()) {
			attr_values.add(new StringAttributeValue(jsonValue.textValue()));
		}
		else {
			logger.error("domino response attribute " + jsonKey + " value not string");
			logger.error("response body = " + body);
			return "invalid domino response";
		}

		final IdPAttribute attr=new IdPAttribute(jsonKey);
		attr.setValues(attr_values);
		principals.add(new IdPAttributePrincipal(attr));
	}

	principals.add(new AuthnContextClassRefPrincipal("urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport"));
	principals.add(new AuthnContextClassRefPrincipal("urn:oasis:names:tc:SAML:2.0:ac:classes:Password"));

	if (mfa) {
		final String dominoMFAPrincipal =
			environment.getProperty("idp.authn.External.domino.MFAPrincipal");
		if (dominoMFAPrincipal != null) {
			principals.add(new AuthnContextClassRefPrincipal(dominoMFAPrincipal));
		}
		else {
			logger.warn("domino MFAPrincipal property not found");
		}
	}

	request.setAttribute(ExternalAuthentication.SUBJECT_KEY,
		new Subject(false, principals, Collections.EMPTY_SET, Collections.EMPTY_SET));

	ExternalAuthentication.finishExternalAuthentication(callback_key != null ?
						callback_key : redirect_key, request, response);

	return null;
}
%>

<%
try {
	// Access spring environment to lookup properties
	final ApplicationContext applicationContext = RequestContextUtils.findWebApplicationContext(request);
	final Environment environment = applicationContext.getEnvironment();
	final String dominoSessionCookie = environment.getProperty("idp.authn.External.domino.SessionCookie");

	// Check if there's an existing domino session - this should always be true for
	// callback processing, but might be true before authentication redirect if user
	// already has an established session
	boolean domino_session = false;
	if (dominoSessionCookie != null) {
		Cookie[] cookies = request.getCookies();
		if (cookies != null) {
			for (Cookie cookie : cookies) {
				if (cookie.getName().equals(dominoSessionCookie)) {
					domino_session = true;
					logger.debug("found domino session cookie - " + cookie.getValue());
					break;
				}
			}
		}
	}

	final String callback_key = request.getParameter("idp_key");

	// If we don't have a callback key, we're in the pre-redirect stage of the external
	// authentication process, so we need to set it up
	String redirect_key = null;
	if (callback_key == null) {
		redirect_key = ExternalAuthentication.startExternalAuthentication(request);
		logger.debug("processing initial pre-redirect call - " + redirect_key);
	}
	else {
		logger.debug("processing redirect callback - " + callback_key);
	}

	// If there's either an existing domino session, or we are processing the redirect
	// callback, try to validate the domino session
	if (domino_session || callback_key != null) {
		String validate_error = validate_session(environment, request, response,
						callback_key, redirect_key);

		// If validation succeeds, we're good to go, so hand back to idp
		if (validate_error == null) {
			return;
		}
		// Otherwise, if it failed, and we're processing the redirect callback, pass the
		// failure through
		else if (callback_key != null) {
			request.setAttribute(ExternalAuthentication.AUTHENTICATION_ERROR_KEY, validate_error);
			ExternalAuthentication.finishExternalAuthentication(callback_key, request, response);
			return;
		}
	}

	// If we reach here, there wasn't an existing valid domino session and we need to
	// send the user to domino to authenticate

	// This assumes domino is running on same server on standard ports
	final String dominoURL = request.getScheme() + "://" + request.getServerName() +
							 "/names.nsf?open&idp_key=" + redirect_key;

	logger.debug("redirecting to domino auth - " + dominoURL);
	response.sendRedirect(dominoURL);

} catch (final ExternalAuthenticationException e) {
	throw new ServletException("Error processing external authentication request", e);
}
%>
