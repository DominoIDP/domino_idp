<%@ page pageEncoding="UTF-8" %>
<%@ page import="javax.servlet.http.*" %>
<%@ page import="java.io.*" %>
<%@ page import="java.lang.*" %>

<%
	String contentType = request.getContentType();

	out.println("<html>");
	out.println("<head>");
	out.println("<title>Keycloak SP metadata upload</title>");  
	out.println("</head>");
	out.println("<body>");

	if (contentType != null && contentType.indexOf("multipart/form-data") >= 0) {
		final Part filePart = request.getPart("file");
		OutputStream output = null;
		InputStream filecontent = null;

		try {
			output = new FileOutputStream(new File("/opt/shibboleth-idp/metadata/keycloak-sp.xml"));
			filecontent = filePart.getInputStream();

			int read = 0;
			final byte[] bytes = new byte[1024];

			while ((read = filecontent.read(bytes)) != -1) {
				output.write(bytes, 0, read);
			}

			out.println("<h1>Metadata upload successful</h1>");

			try {
				Process p = Runtime.getRuntime().exec("/opt/shibboleth-idp/bin/reload-service.sh -u http://localhost:8080/idp -id shibboleth.MetadataResolverService");
				p.waitFor();
				if (p.exitValue() == 0) {
					out.println("<h2>Metadata reload successful</h2>");
				}
				else {
					out.println("<h2>Metadata reload failed - exit code " + p.exitValue() + "</h2>");
				}
			} catch (Exception e) {
				out.println("<h2>Metadata reload failed - exception " + e.getMessage() + "</h2>");
			}
		} catch (FileNotFoundException fne) {
			out.println("<h1>Metadata upload failed - " + fne.getMessage() + "</h1>");
		} finally {
			if (output != null) {
				output.close();
			}
			if (filecontent != null) {
				filecontent.close();
			}
		}
	}
	else {
		out.println("<h1>Upload keycloak SP metadata</h1>");
		out.println("<form method=\"POST\" action=\"" + request.getRequestURI() +"\" enctype=\"multipart/form-data\">");
		out.println("File: <input type=\"file\" name=\"file\" />");
		out.println("<input type=\"submit\" value=\"Upload\" />");
		out.println("</form>");
	}

	out.println("</body>");
	out.println("</html>");

%>
