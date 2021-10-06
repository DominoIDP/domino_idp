<%@ page pageEncoding="UTF-8" %>
<%@ page import="net.shibboleth.idp.authn.*" %>
<%@ page import="net.shibboleth.idp.attribute.*"%>
<%@ page import="net.shibboleth.idp.authn.principal.*"%>
<%@ page import="java.security.*"%>
<%@ page import="javax.security.auth.*"%>
<%@ page import="java.util.*"%>
<%@ page import="java.net.http.*"%>
<%@ page import="com.fasterxml.jackson.databind.ObjectMapper"%>
<%@ page import="com.fasterxml.jackson.databind.JsonNode"%>

<%
try {
	final org.slf4j.Logger logger = org.slf4j.LoggerFactory.getLogger("external_auth");
	final String qkey = request.getParameter("idp_key");

	// If no key parameter, redirect to domino auth page
	if (qkey == null) {
		final String key = ExternalAuthentication.startExternalAuthentication(request);

		// This assumes domino is running on same server on standard ports
		final String dominoURL = request.getScheme() + "://" + request.getServerName() +
								 "/names.nsf?open&idp_key=" + key;

		logger.debug("redirecting to domino auth - " + dominoURL);
		response.sendRedirect(dominoURL);
	}
	// User coming back from domino auth, validate session and acquire attributes
	else {
		logger.debug("evaluating redirect return, key = " + qkey);

		final String cookie_header = request.getHeader("Cookie");
		logger.debug("request cookies = " + cookie_header);

		final HttpClient http_client = HttpClient.newHttpClient();

		// This assumes domino is running on same server on standard ports
		final String validate_url = request.getScheme() + "://" +
						request.getServerName() + "/idpproxy.nsf/validate";
		logger.debug("validation URL = " + validate_url);

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

			request.setAttribute(ExternalAuthentication.AUTHENTICATION_ERROR_KEY,
				"domino validation call failed");
			ExternalAuthentication.finishExternalAuthentication(qkey, request, response);
			return;
		}

		if (validate_response.statusCode() != 200) {
			logger.error("domino validation call failed, status = " + validate_response.statusCode());

			request.setAttribute(ExternalAuthentication.AUTHENTICATION_ERROR_KEY,
				"domino validation call failed");
			ExternalAuthentication.finishExternalAuthentication(qkey, request, response);
			return;
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

			request.setAttribute(ExternalAuthentication.AUTHENTICATION_ERROR_KEY,
				"invalid domino response");
			ExternalAuthentication.finishExternalAuthentication(qkey, request, response);
			return;
		}
		catch (com.fasterxml.jackson.core.JsonProcessingException e) {
			logger.error("json processing failed - " + e.toString());
			logger.error("response body = " + body);

			request.setAttribute(ExternalAuthentication.AUTHENTICATION_ERROR_KEY,
				"invalid domino response");
			ExternalAuthentication.finishExternalAuthentication(qkey, request, response);
			return;
		}

		final JsonNode statusNode = jsonRoot.get("status");
		if (statusNode == null) {
			logger.error("domino response status not found");
			logger.error("response body = " + body);

			request.setAttribute(ExternalAuthentication.AUTHENTICATION_ERROR_KEY,
				"invalid domino response");
			ExternalAuthentication.finishExternalAuthentication(qkey, request, response);
			return;
		}
		else if (!statusNode.isNumber()) {
			logger.error("domino response status not numeric");
			logger.error("response body = " + body);
			request.setAttribute(ExternalAuthentication.AUTHENTICATION_ERROR_KEY,
				"invalid domino response");
			ExternalAuthentication.finishExternalAuthentication(qkey, request, response);
			return;
		}
		else if (statusNode.intValue() != 1) {
			logger.error("domino response status not successful - " + statusNode.intValue());
			request.setAttribute(ExternalAuthentication.AUTHENTICATION_ERROR_KEY,
				"domino validation failed");
			ExternalAuthentication.finishExternalAuthentication(qkey, request, response);
			return;
		}

		final JsonNode usernameNode = jsonRoot.get("username");
		if (usernameNode == null) {
			logger.error("domino response username not found");
			logger.error("response body = " + body);
			request.setAttribute(ExternalAuthentication.AUTHENTICATION_ERROR_KEY,
				"invalid domino response");
			ExternalAuthentication.finishExternalAuthentication(qkey, request, response);
			return;
		}
		else if (!usernameNode.isTextual()) {
			logger.error("domino response username not string");
			logger.error("response body = " + body);
			request.setAttribute(ExternalAuthentication.AUTHENTICATION_ERROR_KEY,
				"invalid domino response");
			ExternalAuthentication.finishExternalAuthentication(qkey, request, response);
			return;
		}
		else if (usernameNode.textValue().isEmpty()){
			logger.error("domino response username empty");
			request.setAttribute(ExternalAuthentication.AUTHENTICATION_ERROR_KEY,
				"invalid domino response");
			ExternalAuthentication.finishExternalAuthentication(qkey, request, response);
			return;
		}

		final HashSet<Principal> principals=new HashSet<Principal>();
		principals.add(new UsernamePrincipal(usernameNode.textValue()));

		final JsonNode attributesNode = jsonRoot.get("attributes");
		if (attributesNode == null) {
			logger.error("domino response attributes not found");
			logger.error("response body = " + body);
			request.setAttribute(ExternalAuthentication.AUTHENTICATION_ERROR_KEY,
				"invalid domino response");
			ExternalAuthentication.finishExternalAuthentication(qkey, request, response);
			return;
		}
		else if (!attributesNode.isObject()) {
			logger.error("domino response attributes not object");
			logger.error("response body = " + body);
			request.setAttribute(ExternalAuthentication.AUTHENTICATION_ERROR_KEY,
				"invalid domino response");
			ExternalAuthentication.finishExternalAuthentication(qkey, request, response);
			return;
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
						request.setAttribute(ExternalAuthentication.AUTHENTICATION_ERROR_KEY,
							"invalid domino response");
						ExternalAuthentication.finishExternalAuthentication(qkey, request, response);
						return;
					}
				}
			}
			else if (jsonValue.isTextual()) {
				attr_values.add(new StringAttributeValue(jsonValue.textValue()));
			}
			else {
				logger.error("domino response attribute " + jsonKey + " value not string");
				logger.error("response body = " + body);
				request.setAttribute(ExternalAuthentication.AUTHENTICATION_ERROR_KEY,
					"invalid domino response");
				ExternalAuthentication.finishExternalAuthentication(qkey, request, response);
				return;
			}

			final IdPAttribute attr=new IdPAttribute(jsonKey);
			attr.setValues(attr_values);
			principals.add(new IdPAttributePrincipal(attr));
		}

		request.setAttribute(ExternalAuthentication.SUBJECT_KEY,
			new Subject(false, principals, Collections.EMPTY_SET, Collections.EMPTY_SET));

		ExternalAuthentication.finishExternalAuthentication(qkey, request, response);
	}
} catch (final ExternalAuthenticationException e) {
	throw new ServletException("Error processing external authentication request", e);
}
%>
