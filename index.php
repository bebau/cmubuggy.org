<?php
  include_once("dbconfig.inc");
  include_once("lib/pChart_includes.inc");
  include_once("util.inc");
  session_start();

  $s = null;
  if(isset($_GET["s"])) {
    $s = $_GET["s"];
  }
  $title = "CMU Buggy Alumni Association";
  $headline = "Records: 2:02.16, 2:23.27";

  switch($s){
    case "about":
      $title = "About | ".$title;
      $headline = "About";
      break;
    case "buzz":
      $title = "Buzz | ".$title;
      $headline = "Live Buggy Chat";
      break;
    case "history":
      $title = "History | ".$title;
      $headline = "History";
      $dbname = "cmubuggy_pog";
      break;
    case "live":
      $title = "Live! | ".$title;
      $headline = "Live Streaming Buggy";
      break;
    case "search":
      $title = "Search Results | ".$title;
      $headline = "Search Results";
      break;
    case "seniors":
      $title = "Seniors | ".$title;
      $headline = "You're alumni now, class of ".date('Y');
      break;
    case "store":
      $title = "Store | ".$title;
      $headline = "Merchandise and souveniers!";
      break;
    case "raceday":
      $title = "Raceday | ".$title;
      $headline = "Raceday!";
      break;
    case "video":
    case "videolist":
      $title = "Videos | ".$title;
      $headline = "Video Archives";
      break;
    case "events":
      $title = "Events | ".$title;
      $headline = "Events";
      break;
  }

  if(empty($s)){
    $content = ("./content/homepage.inc");
  } else if(file_exists("./content/".$s.".inc")){
    $content = "./content/".$s.".inc";
  } else {
    $content = "./content/404.inc";
    $title = "Not Found | ".$title;
    $headline = "Not Found";
  }
?>
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf8">
  <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
  <meta name="keywords" content="" />
  <meta name="description" content="" />
  <meta name="google-site-verification" content="GXsMGGkXYJADa-Rw8I0azRbCk_ILRSXWwTkiHODCBrw" />
  <title><?php echo($title); ?></title>
  <?php include_once(ROOT_DIR."/content/cssjs.inc"); ?>
</head>
<?php
  include_once("content/pre-content.inc");
  include_once($content);
  include_once("content/post-content.inc");
?>
</body>
</html>
