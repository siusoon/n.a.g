<?php
// fullpath is the pattern for selecting the images from the source directory
//$fullpath = "/var/www/nag_05_b1_gal-rpi/gallery/thumbs/*@*.*";
$fullpath = "/var/www/nag_05_b1_gal-rpi/thumb/*@*.*";
// newbase defines the base path to use for the image links
//$newbase = "thumbs/";
$newbase = "http://192.168.0.1/thumb/";

// The size in pixels used to draw thumbnails
$size = 24;
if (isset($_GET['size'])) {
  $getSize = filter_var($_GET['size'], FILTER_SANITIZE_NUMBER_INT);
  // Make sure the size of the thumbnails is between 5px and 400px.
  if ($getSize >= 5 && $getSize <= 400) {
    $size = $getSize;
  }
}

// imgLimit defines the number of thumbnails which should be drawn
$imgLimit = 2769;
if (isset($_GET['limit'])) {
  $getLimit = filter_var($_GET['limit'], FILTER_SANITIZE_NUMBER_INT);
  // Make sure the grid is built out of between 400 and 4000 thumbnails.
  if ($getLimit >= 400 && $getLimit <= 4000) {
    $imgLimit = $getLimit;
  }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
<?php
if (!isset($_GET['refresh']) || filter_var($_GET['refresh'], FILTER_SANITIZE_STRING) != "n") {
  echo"  <meta http-equiv='refresh' content='300'>";
}
?>

  <title>nag_extensions</title>

  <style>
  html, body {
    width: 100%;
    max-width: 100%;
    height: 100%;
    max-height: 100%;
    background-color: #ddd;
    margin: 0;
  }

  body {
    overflow: hidden;
  }

  h4 {
    margin: 0.1em 0 0 0;
  }

  figure {
    border: 1px dashed #555;
<?php
echo "    width: " . $size . "px;\n";
echo "    height: " . $size . "px;\n";
?>
    line-height: 2px;
    margin: 0px 1px 0px 0px;
  }

  figure img {
    height: inherit;
    line-height: inherit;
  }

  figure img:hover {
    cursor: pointer;
  }

  .wrapImages {
    height: inherit;
    max-height: inherit;
    width: inherit;
    max-width: inherit;
    display: flex;
    flex-wrap: wrap;
    justify-content: space-around;
  }

  /* Menu */

  #dim {
    display: flex;
    justify-content: center;
    align-items: center;
    position: absolute;
    top: 0;
    margin: 0;
    padding: 0;
    width: 100%;
    height: 100%;
    background: #000a;
    z-index: 300;
  }

  #modal {
    display: flex;
    margin: 0;
    padding: 0;
    min-width: 30%;
    max-width: 90%;
    min-height: 15%;
    max-height: 90%;
    background: #ddd;
    border: #555 1px dashed;
    z-index: 400;
  }

  #detailImg {
    width: 75%;
    margin: 0;
    padding: 0;
    border: 0;
  }

  #detailInfo {
    width: 25%;
    margin: 0;
    padding: 20px 20px 0 20px;
    border: 0;
    border-left: #555 1px dashed;
  }

  #detailClose {
    position: absolute;
    padding: 0;
    margin: 0;
    top: 0.5%;
    right: 0.5%;
    width: 1.2em;
    height: 1.2em;
    text-align: center;
    vertical-align: center;
    background: none;
    color: #ddd;
    border: none;
    border-radius: 1.2em;
    font-size: 1.2em;
    text-decoration: none;
    font-weight: bold;
  }

  #detailClose:hover {
    color: #fff;
  }
  </style>
</head>
<body>
  <!-- The Net.Art Generator gallery extension -->
  <!-- GCB (d7dd0d), 2019 -->
  <div class="wrapImages">
<?php
// we use GLOB_NOSORT since we don't want to sort based on the file name
$images = glob( $fullpath, GLOB_NOSORT );
// we sort the array ourselves: depending on file modification date
usort($images, function($a, $b) {
  return filemtime($a) < filemtime($b);
});

// curVal holds the current value of iterations while building the grid.
$curVal = 0;
foreach ($images as $image) {
  if ($curVal == $imgLimit) {
    break;
  }

  $child = basename($image);
  $expChild = explode("@", $child);
  $signature = explode("-", $expChild[0], 2);
  $author = $signature[0];
  $title = str_replace("_", " ", $signature[1]);

  $entry = "<figure><img src='" . $newbase . $child . "' alt='" . $author . ": " . $title . "'></figure>";

  echo $entry;
  $curVal++;
}

if ($imgLimit > $curVal) {
  // Fill the remaining page with placeholders
  while ($imgLimit > $curVal) {
    echo "<figure></figure>";
    $curVal++;
  }
}
?>
  </div>
  <script>
  function hideModal() {
    var bg = document.getElementById("dim");
    if (bg === null) {
      return;
    }

    document.body.removeChild(bg);
  }

  function showModal(img) {
    // Dim background (put a layer above the screen)
    var bg = document.getElementById("dim");
    if (bg === null) {
      var dim = document.createElement("div");
      dim.id = "dim";
      dim.onclick = function(e) {
          e.preventDefault();
          hideModal();
        };
      document.body.appendChild(dim);
      bg = document.getElementById("dim");
    }

    // Create the actual modal with embedded NAG image details
    var modal = document.getElementById("modal");
    if (modal === null) {
      var modal = document.createElement("div");
      modal.id = "modal";

      var dImg = document.createElement("img");
      dImg.id = "detailImg";
      dImg.src = "http://192.168.0.1/gen/" + img;

      var expImg = img.split("@");
      var signature = expImg[0].split("-", 2);
      var author = signature[0];
      var title = signature[1].replace(/_/g, " ");
      var expStamp = expImg[1].split("_");
      var expTime = expStamp[2].split(".");
      var timestamp = expStamp[1] + " " + expStamp[0] + " " + expStamp[3].split(".")[0] + " " + expTime[0] + ":" + expTime[1] + ":" + expTime[2];

      var dInf = document.createElement("div");
      dInf.id = "detailInfo";
      dInf.innerHTML = "<h4>" + author + ": " + title + "</h4><hr>" + timestamp;

      modal.appendChild(dImg);
      modal.appendChild(dInf);
    }

    var dClose = document.createElement("button");
    dClose.id = "detailClose";
    dClose.innerHTML = "&times;";
    dClose.onclick = function(e) {
        e.preventDefault();
        hideModal();
      };

    bg.appendChild(dClose);
    bg.appendChild(modal);
  }

  // Bind to document to grab clicks on thumbnails
  (function() {
    document.body.onclick = function(e) {
      if (e.target.tagName !== "IMG") {
        return
      }

      $splitted = e.target.src.split("/");
      showModal($splitted[$splitted.length - 1]);
    }
  }());
  </script>
</body>
</html>
