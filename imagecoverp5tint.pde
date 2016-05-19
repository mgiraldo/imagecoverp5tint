import gab.opencv.*;
import controlP5.*;
import java.awt.Rectangle;
import java.util.Arrays;

// constants
int SCREENWIDTH = 2400;
int SCREENHEIGHT = 1300;
int ARTWORKSTARTX = 400;
int ARTWORKSTARTY = 75;
int COVERWIDTH = 360;
int COVERHEIGHT = 300;
float COVERRATIO = float(COVERWIDTH) / float(COVERHEIGHT);
int MARGIN = 10;
int IMAGEMARGIN = 10;
int TITLEHEIGHT = 100;
int AUTHORHEIGHT = 50;
int BACKGROUNDCOLOR = 128;
int MAXAUTHORCHAR = 24;
int MAXTITLECHAR = 80;
int BORDERTHICKNESS = 4; // percent

// mode (if command line or gui)
// command line args:
// images_folder book_json output_folder title_font author_font
boolean is_command_line = false;

PGraphics pg;

OpenCV opencv;
Rectangle[] faces;

ControlP5 cp5;

DropdownList titleFontList;
DropdownList authorFontList;

int borderThick = 5; // percent
int baseSaturation = 50;//70;
int baseBrightness = 100;//85;
int imageBrightness = -200;
int imageAlpha = 10;
int topMargin = 220;
int textBackgroundAlpha = 200;
int lineThickness = 0;
int colorDistance = 270;
boolean faceDetect = false;
boolean invert = false;
boolean batch = false;

ArrayList<PImage> images;
ArrayList<String> image_names;
ArrayList<PImage> covers;

JSONArray json_images;

PFont titleFont;
PFont authorFont;
int titleSize;
int authorSize;

color baseColor;
color otherColor;
color textColor = color(0);
boolean refresh = true;
String[] bookList;
int currentBook = 0;
int currentId = 0;
String title = "";
String author = "";
String filename = "";
String baseFolder = "";
String[] bookJsonFile;
String outputFolder = "";

int startTime = 0;
int imageCounter = 0;
int startID = 0;

int currentCover = 0;

void setup() {
  println("args:" + args.length);
  if (args.length == 5) {
    println("command line:" + args[0] + ":" + args[1] + ":" + args[2] + ":" + args[3] + ":" + args[4]);
    is_command_line = true;
  }

  size(SCREENWIDTH, SCREENHEIGHT);
  background(255);
  noStroke();
  images = new ArrayList<PImage>();
  covers = new ArrayList<PImage>();
  image_names = new ArrayList<String>();

  pg = createGraphics(COVERWIDTH, COVERHEIGHT);

  if (!is_command_line) {
    selectFolder("Select a folder to process:", "folderSelected");
    cp5 = new ControlP5(this);
    controlP5Setup();
    loadData();
  } else {
    baseFolder = args[0];
    outputFolder = args[1];
    bookJsonFile = loadStrings(args[2]);
    String title_font = args[3];
    int fontSize = 14;
    titleFont = createFont(title_font, fontSize);
    titleSize = fontSize;
    String author_font = args[4];
    fontSize = 14;
    authorFont = createFont(author_font, fontSize);
    authorSize = fontSize;
    batch = true;
    executeDraw();
    // kill this before it shows a window
    exit();
  }
}

void controlP5Setup() {
  cp5.addSlider("baseSaturation")
    .setPosition(10,5)
    .setRange(0,100)
    .setSize(200,10)
    .setId(3)
    ;
  cp5.addSlider("baseBrightness")
    .setPosition(10,20)
    .setRange(0,100)
    .setSize(200,10)
    .setId(3)
    ;
  cp5.addSlider("colorDistance")
    .setPosition(10,35)
    .setRange(0,360)
    .setSize(200,10)
    .setId(3)
    ;
  cp5.addSlider("COVERWIDTH")
    .setPosition(300,5)
    .setRange(200,3700)
    .setSize(400,10)
    .setId(3)
    ;
  cp5.addSlider("textBackgroundAlpha")
    .setPosition(300,20)
    .setRange(0,255)
    .setSize(400,10)
    .setId(3)
    ;
  cp5.addSlider("BORDERTHICKNESS")
    .setPosition(300,35)
    .setRange(0,10)
    .setSize(400,10)
    .setId(3)
    ;
  cp5.addToggle("faceDetect")
     .setPosition(810,5)
     .setSize(50,20)
     .setMode(ControlP5.SWITCH)
     ;
  cp5.addToggle("invert")
     .setPosition(870,5)
     .setSize(50,20)
     .setMode(ControlP5.SWITCH)
     ;
  cp5.addToggle("batch")
     .setPosition(930,5)
     .setSize(50,20)
     .setMode(ControlP5.SWITCH)
     ;

  cp5.addTextfield("inputID")
     .setPosition(990,5)
     .setSize(100,20)
     .setFocus(true)
     .setColor(color(255,0,0))
     ;

  titleFontList = cp5.addDropdownList("titleList")
         .setPosition(1100, 15)
         .setSize(150, 200)
         ;

  titleFontList.captionLabel().toUpperCase(true);
  titleFontList.captionLabel().set("Font");
  titleFontList.addItem("ACaslonPro-Regular", 0);
  titleFontList.addItem("ACaslonPro-Italic", 1);
  titleFontList.addItem("ACaslonPro-Semibold", 2);
  titleFontList.addItem("AvenirNext-Bold", 3);
  titleFontList.addItem("AvenirNext-Regular", 4);
  titleFontList.setIndex(3);

  authorFontList = cp5.addDropdownList("authorList")
         .setPosition(1270, 15)
         .setSize(150, 200)
         ;

  authorFontList.captionLabel().toUpperCase(true);
  authorFontList.captionLabel().set("Font");
  authorFontList.addItem("ACaslonPro-Italic", 0);
  authorFontList.addItem("ACaslonPro-Regular", 1);
  authorFontList.addItem("AvenirNext-Bold", 2);
  authorFontList.addItem("AvenirNext-Regular", 3);
  authorFontList.setIndex(0);
}

void draw() {
  executeDraw();
}

void executeDraw() {
  background(255);
  fill(50);
  rect(0, 0, SCREENWIDTH, 50);
  if (baseFolder!="") {
    int tempID = 0;
    if (!is_command_line) tempID = int(cp5.get(Textfield.class,"inputID").getText());
    if (tempID!=0 && tempID!=startID) {
      startID = tempID;
      int index = getIndexForBookId(startID);
      println("tempID:" + tempID + " index:" + index);
      if (index!=-1) {
        currentBook = index;
      }
    }
    if (refresh) {
      refresh = false;
      COVERHEIGHT = int(COVERWIDTH * 1.5);
      COVERRATIO = float(COVERWIDTH) / float(COVERHEIGHT);
      borderThick = int(COVERWIDTH*BORDERTHICKNESS / 100);
      MARGIN = int(COVERHEIGHT * 0.05);
      titleSize = int(COVERWIDTH * 0.08);
      authorSize = int(COVERWIDTH * 0.08);
      topMargin = int(COVERHEIGHT * 0.68);
      pg = createGraphics(COVERWIDTH, COVERHEIGHT);
      parseBook();
      createCovers();
      // if (images.size() == 0) {
      //   println("BOOK HAS NO USEFUL IMAGES");
      // }
      if (!is_command_line) cp5.get(Textfield.class,"inputID").setText(""+currentId);
    }
    // if (images.size() > 0) {
      drawCovers();
    // }
  }
  if (batch) {
    saveCurrent();
    refresh = true;
    currentBook++;
    if (!is_command_line && currentBook >= bookList.length) {
      currentBook = 0;
      batch = false;
      refresh = false;
      int endTime = millis();
      int seconds = round((endTime - startTime)*.001);
      int minutes = round(seconds/60);
      println("Processing " + imageCounter + " images for " + bookList.length + " books took " + minutes + " minutes (" + seconds + " seconds)");
    }
  }
}

void drawCovers() {
  int i, l;
  l = images.size();
  int colWidth = COVERWIDTH + MARGIN;
  int rowHeight = COVERHEIGHT + MARGIN;
  int xini = MARGIN;
  int yini = 60;
  int cols = floor(SCREENWIDTH / (colWidth));
  int col = 0;
  int row = 0;
  int x = 0;
  int y = 0;
  // println(images);
  // for (i=0;i<l;i++) {
    x = xini + (col * (colWidth));
    y = yini + (row * rowHeight);
    image(covers.get(0), x, y);
    col++;
    if (col >= cols) {
      col = 0;
      row++;
    }
  // }
}

void createCovers() {
  covers.clear();
  int i, l = json_images.size();

  if (l==0) return;

  // for (i=0;i<l;i++) {
    covers.add(createCover(currentCover));
  // }
}

PImage createCover(int index) {
  pg.clear();
  pg.beginDraw();
  drawBackground(pg, 0, 0);
  drawArtwork(pg, index, 0, 0);
  drawText(pg, 0, 0);
  pg.endDraw();
  return pg.get();
}

void loadData() {
  bookList = loadStrings("test-book.json");
  // config = loadStrings("ids.txt");
}

void getBookImages() {
  imageCounter = 0;
  images.clear();
  image_names.clear();

  PImage temp, img, imgBW;
  int i;
  float w, h;

  int l = json_images.size();

  // println("ratio:" + COVERRATIO);
  for (i=0;i<l;i++) {
    getBookImage(i);
    imageCounter++;
  }
}

PImage getBookImage(int index) {
  PImage temp, img, imgBW;
  float w, h;

  // int l = json_images.size();

  // println("ratio:" + COVERRATIO);
  // for (i=0;i<l;i++) {
    String path = json_images.getString(index);

    if (path.toLowerCase().indexOf("cover") != -1
      || path.toLowerCase().indexOf("title") != -1
      || path.toLowerCase().indexOf("page-images") != -1
      || path.toLowerCase().indexOf("thumb") != -1
      || path.endsWith("-t.jpg")
      || path.endsWith("t.jpg")
      || path.endsWith("s.jpg")
      || path.endsWith("m.jpg")
      || (!path.endsWith(".jpg") && !path.endsWith(".png"))) {
      // skip generic covers (usually named "cover.jpg" or "title.jpg")
      // return new PImage();
    }

    path = baseFolder + path.replace("./","");
    println("loading:" + path);
    temp = loadImage(path);
    if (temp == null || temp.width <= 0 || temp.height <= 0) {
      // return new PImage();
    }
    // check for faces (not faeces)
    if (faceDetect) {
      opencv = new OpenCV(this, temp);
      opencv.loadCascade(OpenCV.CASCADE_FRONTALFACE);
      faces = opencv.detect();
      if (faces.length > 0) {
        temp = temp.get(faces[0].x-40, faces[0].y-40, faces[0].width+60, faces[0].height+100);
        // for (int i = 0; i < faces.length; i++) {
        //   rect(faces[i].x, faces[i].y, faces[i].width, faces[i].height);
        // }
      }
    }
    // end opencv
    w = temp.width;
    h = temp.height;
    float ratio = w/h;
    int padding = borderThick*2;
    println("cratio:" + COVERRATIO + " w:" + temp.width + " h:" + temp.height + " r:" + ratio + " padd:" + padding);
    if (ratio >= COVERRATIO) {
      // temp.resize(COVERWIDTH-IMAGEMARGIN*2, 0);
      temp.resize(0, COVERHEIGHT);
      imgBW = temp.get(int((temp.width-COVERWIDTH)*.5)+borderThick, borderThick, COVERWIDTH - padding, COVERHEIGHT - padding);
      // println("wider");
    } else {
      // temp.resize(0, maxHeight);
      temp.resize(COVERWIDTH, 0);
      imgBW = temp.get(borderThick, int((temp.height-COVERHEIGHT)*.5)+borderThick, COVERWIDTH - padding, COVERHEIGHT - padding);
      // println("taller");
    }
    println(" w:" + temp.width + " h:" + temp.height + " bw:" + imgBW.width + " bh:" + imgBW.height);
    println(" cw:" + COVERWIDTH + " ch:" + COVERHEIGHT);
    imgBW.filter(GRAY);
    // if (invert) {
    //   imgBW.filter(INVERT);
    // }
    img = imgBW.get();//0, 0, COVERWIDTH - MARGIN - padding, COVERHEIGHT - MARGIN - padding);
    // imgBW = imgBW.get(0, topMargin-MARGIN, COVERWIDTH - padding, COVERHEIGHT-topMargin+MARGIN - padding);

    pg.clear();
    pg.beginDraw();
    pg.background(baseColor);
    pg.tint(baseColor);
    pg.image(img, borderThick, borderThick);
    // for bicolor photo
    pg.noTint();
    // pg.image(imgBW, 0, topMargin-MARGIN);
    // end bicolor photo
    pg.endDraw();
    return pg.get();
  // }
}

JSONObject getBook(String[] list, int index) {
  int l = list.length;
  int i;
  JSONObject book = new JSONObject();
  book = JSONObject.parse(list[index]);
  return book;
}

int getIndexForBookId(int id) {
  int l = bookList.length;
  int i;
  JSONObject book = new JSONObject();
  for (i=0;i<l;i++) {
    book = JSONObject.parse(bookList[i]);
    int bid = book.getInt("identifier");
    if (id == bid) {
      return i;
    }
  }
  return -1;
}

void parseBook() {
  JSONObject book;
  if (!is_command_line) {
    book = getBook(bookList, currentBook);
  } else {
    book = getBook(bookJsonFile, 0);
  }

  currentId = book.getInt("identifier");

  println("book id:" + currentId);

  title = book.getString("title");
  String subtitle = "";
  String shorttitle = "";
  String json_author = "";

  try {
    subtitle = book.getString("subtitle");
  }
  catch (Exception e) {
    println("book has no subtitle");
  }
  if (!subtitle.equals("") && title.length() + subtitle.length() + 2 <= MAXTITLECHAR) {
    title = title + ": " + subtitle;
  }

  try {
    shorttitle = book.getString("title_short");
  }
  catch (Exception e) {
    // println("book has no short authors");
  }
  if (!shorttitle.equals("") && title.length() > MAXTITLECHAR) {
    title = shorttitle;
  }

  title = title.toUpperCase();

  try {
    json_author = book.getString("authors_long");
  }
  catch (Exception e) {
    println("book has no authors");
  }
  if (!json_author.equals("")) {
    author = json_author;
  } else {
    author = "";
  }

  // now try the short author
  json_author = "";

  try {
    json_author = book.getString("authors_short");
  }
  catch (Exception e) {
    println("book has no short authors");
  }
  if (!json_author.equals("") && author.length() > MAXAUTHORCHAR) {
    author = json_author;
  }

  filename = book.getString("identifier") + ".png";

  processColors();

  json_images = book.getJSONArray("illustrations");

  imageCounter = json_images.size();
}

void processColors() {
  int counts = title.length() + author.length();
  int colorSeed = int(map(counts, 6, MAXTITLECHAR+MAXAUTHORCHAR, 30, 300));
  colorMode(HSB, 360, 100, 100);
  color lightColor = color((colorSeed+colorDistance)%360, baseSaturation+20, baseBrightness);
  color darkColor = color(colorSeed, baseSaturation-20, baseBrightness-20);
  otherColor = lightColor;
  baseColor = darkColor;
  if (invert) {
    baseColor = lightColor;
    otherColor = darkColor;
  }
  // println("baseColor:"+baseColor);
  colorMode(RGB, 255);
}

void drawArtwork(PGraphics g, int index, int _x, int _y) {
  PImage img = getBookImage(index);
  int x = _x; //+int((COVERWIDTH - img.width) * .5);
  int y = _y; //+int((COVERHEIGHT - img.height) * .5);
  g.image(img, x, y);
}

void drawBackground(PGraphics g, int x, int y) {
  g.fill(BACKGROUNDCOLOR);
  g.rect(x, y, COVERWIDTH, COVERHEIGHT);
}

void drawText(PGraphics g, int x, int y) {
  //…
  MARGIN = int(COVERWIDTH * 0.01);
  int boxStart = y+topMargin-MARGIN;
  int boxHeight = (COVERHEIGHT - topMargin);
  TITLEHEIGHT = int((boxHeight - MARGIN - MARGIN) * 0.5);
  AUTHORHEIGHT = int((boxHeight - MARGIN - MARGIN) * 0.5);
  g.noStroke();
  // for text box
  // g.rect(x, boxStart-lineThickness, COVERWIDTH, borderThick);
  g.fill(255, textBackgroundAlpha);
  g.rect(x, boxStart, COVERWIDTH, COVERHEIGHT-topMargin+MARGIN);
  // end text box
  g.fill(0);
  g.textFont(titleFont, titleSize);
  g.textLeading(titleSize);
  g.textAlign(CENTER);
  // g.fill(otherColor);
  g.text(title, x+MARGIN+borderThick, boxStart+(MARGIN*5), COVERWIDTH - (2 * MARGIN) - (2 * borderThick), TITLEHEIGHT);
  g.textLeading(authorSize);
  g.textFont(authorFont, authorSize);
  g.text(author, x+MARGIN+borderThick, boxStart+TITLEHEIGHT+MARGIN, COVERWIDTH - (2 * MARGIN) - (2 * borderThick), AUTHORHEIGHT);
  // borders
  g.fill(0);
  g.rect((COVERWIDTH-borderThick*2)*.5,boxStart+TITLEHEIGHT+MARGIN-borderThick*.5,borderThick*2,int(COVERWIDTH*0.005));
  g.fill(otherColor);
  g.rect(0,0,borderThick,COVERHEIGHT);
  g.rect(COVERWIDTH-borderThick,0,borderThick,COVERHEIGHT);
  g.rect(0,0,COVERWIDTH,borderThick);
  g.rect(0,COVERHEIGHT-borderThick,COVERWIDTH,borderThick);
}

void saveCurrent() {
  int i, l;
  l = covers.size();
  // println(images);
  for (i=0;i<l;i++) {
    // save here
    PImage temp = covers.get(i); // get(x, y, COVERWIDTH, COVERHEIGHT);
    String out = "output/";
    if (is_command_line) out = outputFolder;
    temp.save(out + currentId + "/cover_" + currentId + "_" + i + ".png");
    // end save
  }

}

void keyPressed() {
  if (key == ' ') {
    refresh = true;
    currentBook++;
  } else if (key == 's') {
    saveCurrent();
  }

  if (key == CODED) {
    refresh = true;
    if (keyCode == LEFT) {
      currentBook--;
      currentCover = 0;
    } else if (keyCode == RIGHT) {
      currentBook++;
      currentCover = 0;
    } else if (keyCode == UP) {
      currentCover++;
    } else if (keyCode == DOWN) {
      currentCover--;
    }
  }
  if (currentCover >= imageCounter) {
    currentCover = 0;
  }
  if (currentCover < 0) {
    currentCover = imageCounter-1;
  }
  if (currentBook >= bookList.length) {
    currentBook = 0;
  }
  if (currentBook < 0) {
    currentBook = bookList.length-1;
  }
}

void controlEvent(ControlEvent theEvent) {
  if (theEvent.isController()) {
    if (theEvent.getController().getName().equals("batch")) {
      startTime = millis();
    }
  }

  if (theEvent.isGroup()) {
    // an event from a group e.g. scrollList
    println(theEvent.group().value()+" from "+theEvent.group());
  } else {
    refresh = true;
  }

  if(theEvent.isAssignableFrom(Textfield.class)) {
    println("controlEvent: accessing a string from controller '"
            +theEvent.getName()+"': "
            +theEvent.getStringValue()
            );
  }

  if(theEvent.isGroup() && theEvent.name().equals("titleList")){
    int index = (int)theEvent.group().value();
    String font = titleFontList.getItem(index).getName();
    println("index:"+index + " font:" + font);
    int fontSize = 14;
    titleFont = createFont(font, fontSize);
    titleSize = fontSize;
    refresh = true;
  }

  if(theEvent.isGroup() && theEvent.name().equals("authorList")){
    int index = (int)theEvent.group().value();
    String font = authorFontList.getItem(index).getName();
    println("index:"+index + " font:" + font);
    int fontSize = 14;
    authorFont = createFont(font, fontSize);
    authorSize = fontSize;
    refresh = true;
  }
}

void folderSelected(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else {
    baseFolder = selection.getAbsolutePath() + "/";
    println("User selected " + baseFolder);
  }
}

