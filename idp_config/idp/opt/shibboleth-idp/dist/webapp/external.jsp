<%@ page pageEncoding="UTF-8" %>
<%@ page import="net.shibboleth.idp.authn.*" %>
<%@ page import="net.shibboleth.idp.attribute.*"%>
<%@ page import="net.shibboleth.idp.authn.principal.*"%>
<%@ page import="java.security.*"%>
<%@ page import="javax.security.auth.*"%>
<%@ page import="java.util.*"%>

<%
try {
    String qkey = request.getParameter("key");
    if (qkey == null) {
      final String key = ExternalAuthentication.startExternalAuthentication(request);

	response.sendRedirect(request.getRequestURI() + "?key=" + key);
    }
    else {

	    HashSet<Principal> principals=new HashSet<Principal>();

	    principals.add(new UsernamePrincipal("henson"));

	    IdPAttribute attr=new IdPAttribute("eduPersonNickname");
	    ArrayList<IdPAttributeValue> values = new ArrayList<IdPAttributeValue>();
	    values.add(new StringAttributeValue("Paul Henson"));
	    attr.setValues(values);
	    principals.add(new IdPAttributePrincipal(attr));

	    attr=new IdPAttribute("mail");
	    values = new ArrayList<IdPAttributeValue>();
	    values.add(new StringAttributeValue("henson@signet.id"));
	    attr.setValues(values);
	    principals.add(new IdPAttributePrincipal(attr));

	    request.setAttribute(ExternalAuthentication.SUBJECT_KEY,new Subject(false, principals, Collections.EMPTY_SET, Collections.EMPTY_SET));

	    ExternalAuthentication.finishExternalAuthentication(qkey, request, response);
   }
} catch (final ExternalAuthenticationException e) {
    throw new ServletException("Error processing external authentication request", e);
}
%>
