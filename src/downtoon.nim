import zippy/[tarballs_v1, ziparchives_v1], nimquery, nimja, freeimage
import std/[httpclient, streams, uri, tempfiles, strutils, os, htmlparser, xmltree, macros]
# import nimwkhtmltox/pdf # No PDFs, html works!!!!

type 
  DownToonFileFormat = enum dtDebug, dtRelease, dtRaw
  DownToonCompressionFormats = enum dtcZipfile, dtcTarball
  Options = ref object
    quiet, noCompression: bool
    first, last: int
    output: string
    templateName: string
    compressionType: DownToonCompressionFormats
    fileFormat: DownToonFileFormat




#[ # NO PDF
proc toPDF(html: string, output: string) =
  initPdf()

  let settings = createGlobalSettings()
  settings.setGlobalSetting("out", output)
  
  let conv = createConverter(settings)
  
  let objSettings = createObjectSettings()
  
  conv.addObject(objSettings, html)
  
  conv.convert()
  
  deinitPdf()
]#

# Templates

template downloadAllFramesTemplate(chck: untyped, srcname: untyped, host: untyped): untyped = 
  var images = newSeq[string](0)

  if o.quiet:
    for i, element in elements:
      let src = element.attr(srcname).strip

      if src.startswith(chck): # If the source url is a valid panel url, add image
        let imgResp = client.get(src)

        if imgResp.status != "200 OK":
          raise newException(ValueError, "Request to image responded with " & imgResp.status)

        var img = imgResp.bodyStream.readAll()

        if imgResp.headers["Content-Type"] == "image/jpeg":
          if not o.noCompression:
            img = compressJpeg(img)



        if o.fileFormat in {dtRaw, dtDebug}: # Raw images for raw mode
          let ext = src.split("/")[^1].split(".")[^1]
          writeFile(dir & "/" & $i & "." & ext, img)
        if o.fileFormat in {dtRelease, dtDebug}:
          images.add getDataUri(img, imgResp.headers["Content-Type"])
  else:
    for i, element in elements:
      let src = element.attr(srcname).strip

      stdout.write("\rGathering: " & url & " [" & $(i + 1) & "/" & $elements.len & "]")

      if src.startswith(chck): # If the source url is a valid panel url, add image
        let imgResp = client.get(src)

        if imgResp.status != "200 OK":
          raise newException(ValueError, "Request to image responded with " & imgResp.status)

        var img = imgResp.bodyStream.readAll()

        if imgResp.headers["Content-Type"] == "image/jpeg":
          if not o.noCompression:
            img = compressJpeg(img)
        else:
          stdout.write("[NON JPEG & NO COMPRESSION]")
        flushFile(stdout)
       
        if o.fileFormat in {dtRaw, dtDebug}: # Raw images for raw mode
          let ext = src.split("/")[^1].split(".")[^1]
          writeFile(dir & "/" & $i & "." & ext, img)
        if o.fileFormat in {dtRelease, dtDebug}:
          images.add getDataUri(img, imgResp.headers["Content-Type"])

    stdout.write("\n")

  if o.fileFormat in {dtRelease, dtDebug}: # If release mode, return html
    return renderChapterHtml(images, o.templateName, host)
  else:
    return ""


template loopThroughAllEpisodesTemplate(makeUrl: untyped, downloadSingle: untyped): untyped =
  for i {.inject.} in o.first..o.last:

    if o.fileFormat in {dtRaw, dtDebug}: # If raw mode, create folder to hold raw files
      createDir(dir & "/episodeRAW_" & $i)
    if not o.quiet:
      stdout.write "Gathering: " & makeUrl
    let xml = client.downloadSingle(makeUrl, dir & "/episodeRAW_" & $i, o) 

    if o.fileFormat in {dtRelease, dtDebug}:
      writeFile(dir & "/episode_" & $i & ".html", xml) # Write html file if release mode








# Utils


proc toString(s: ptr byte, length: uint): string =
  for i in 0..length:
    let charPointer = cast[ptr byte](cast[uint](s) + i.uint)
    result.add cast[char](charPointer[])


proc compressJpeg(imgData: string): string =
  ## Use freeimage to compress the jpeg files

  # Open image
  var mem = FreeImage_OpenMemory(cast[ptr byte](imgData.cstring), imgData.len.uint32)
  var image = FreeImage_LoadFromMemory(FIF_JPEG, mem, JPEG_ACCURATE)
  FreeImage_CloseMemory(mem)

  # Save image
  let FI_DEFAULT = 0.uint8
  var outmem = FreeImage_OpenMemory(addr FI_DEFAULT, FI_DEFAULT.uint32)

  doAssert FreeImage_SaveToMemory(FIF_JPEG, image, outmem, JPEG_OPTIMIZE).bool

  
  # to nim
  var buffer: ptr byte
  var length: uint32
  doAssert FreeImage_AcquireMemory(outmem, addr buffer, addr length).bool 
  # let cs = cast[cstring](buffer)

  result = buffer.toString(length)

  doAssert result.len.uint32 == length + 1 # Ensure converison was sucessful

  # Cleanup
  FreeImage_Unload(image)
  FreeImage_CloseMemory(outmem)


proc renderChapterHtml(images: seq[string], filename: string, src: string): string =
  ## Render `images` using `filename` html template from source `src`. 
  ## Uses nimja, templates can be found in folder.
  
  when defined(release):
    proc basic(images: seq[string]): string =
        compileTemplateFile(getScriptDir() / "basic_release.nimja")
    proc advanced(images: seq[string], src: string): string =
        compileTemplateFile(getScriptDir() / "advanced_release.nimja")
  else:
    proc basic(images: seq[string]): string =
        compileTemplateFile(getScriptDir() / "basic.nimja")
    proc advanced(images: seq[string], src: string): string =
        compileTemplateFile(getScriptDir() / "advanced.nimja")

  case filename
  of "basic":
    return basic(images)
  of "advanced":
    return advanced(images, src)




# Main Body Code

when defined(enableWebtoons):

  include webtoons


proc reaperDownloadSingle(client: HttpClient, url, dir: string, o: Options): string =
  ## Download a single episode from reaper-scans.com

  let resp = client.get(url) # Download episode


  if resp.status != "200 OK":
    raise newException(ValueError, "Request to page responded with " & resp.status)

  let html = resp.bodyStream.readAll()  
  let xml = parseHtml(html)
  let elements = xml.querySelectorAll("img[data-lazyloaded=\"1\"][decoding=\"async\"]") # Find all webcomic panels

  downloadAllFramesTemplate("https://s22.asuracomics.me/s1/scans/", "data-src", "reaper")




proc reaperScans(url: Uri, dir: string, o: Options) =
  ## Download from reaperscans from `uri` with options `o` to `dir`.

  let name = url.path.split("/")[^2]

  let baseUrl = "https://reaper-scans.com/" & name & "-chapter-"
  if not o.quiet:
    echo "Collecting: " & name
  let client = newHttpClient("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36", 0)
  loopThroughAllEpisodesTemplate(baseUrl & $i & "/", reaperDownloadSingle)


proc manhuausDownloadSingle(client: HttpClient, url, dir: string, o: Options): string =


  let resp = client.get(url) # Download episode


  if resp.status != "200 OK":
    raise newException(ValueError, "Request to page responded with " & resp.status)

  let html = resp.bodyStream.readAll()  
  let xml = parseHtml(html)
  let elements = xml.querySelectorAll("div > img.wp-manga-chapter-img") # Find all webcomic panels


  downloadAllFramesTemplate("https://cdn.manhuaus.org/", "data-src", "manhuaus")


proc manhuausOrg(url: Uri, dir: string, o: Options) =
  ## Download from manhuaus.org from `uri` with options `o` to `dir`.
 
  let name = url.path.split("/")[^2] # Extract name
  let baseUrl = $url & "chapter-"
  if not o.quiet:
    echo "Collecting: " & name
  let client = newHttpClient("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36", 0)
  loopThroughAllEpisodesTemplate(baseUrl & $i & "/", manhuausDownloadSingle)


  

proc asuraDownloadSingle(client: HttpClient, url, dir: string, o: Options): string =
  ## Download a single episode from asurascans.com

  let resp = client.get(url) # Download episode

  if resp.status != "200 OK":
    raise newException(ValueError, "Request to page responded with " & resp.status)

  let html = resp.bodyStream.readAll()  
  let xml = parseHtml(html)
  let elements = xml.querySelectorAll("p > img[decoding=\"async\"]") # Find all webcomic panels

  downloadAllFramesTemplate("https://asuratoon.com/wp-content/uploads", "src", "asura")

  

proc asuraScans(url: Uri, dir: string, o: Options) =
  ## Download from asurascan from `uri` with options `o` to `dir`.

  var baseUrl = $url
  baseUrl = baseUrl[0..^4] # Extract url portion that can be modified to change the episode number
  let name = url.path.split("-")[1..^2].join("-") # Find name
  if not o.quiet:
    echo "Collecting: " & name
  let client = newHttpClient("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36", 1) # Fix later
  loopThroughAllEpisodesTemplate(baseUrl & "-" & $i & "/", asuraDownloadSingle)
  

proc downtoon(output="", quiet=false, noCompression=false, first=1, last: int, url: string, 
          templateName="basic", compressionType=dtcTarball, fileFormat=dtRelease) =
  ## Main command


 
  let uri = parseUri(url)
  var tmpdir: string
  when defined(release):
    var options = Options(quiet: quiet, noCompression: noCompression, output: output, first: first, last: last, 
                        templateName: templateName, compressionType: compressionType, fileFormat: fileFormat)
  else:
    # Automatic debug mode
    var options = Options(quiet: quiet, noCompression: noCompression, output: output, first: first, last: last, 
                        templateName: templateName, compressionType: compressionType, fileFormat: dtDebug)

  try:
    case uri.hostname
    of "asuratoon.com":
      if uri.path.endswith("-1/"): # Ensure first episode url instead of title page.
        let name = uri.path.split("-")[1..^2].join("-") # Extract name
        tmpdir = createTempDir(name & "_", "_downtoon") # Create named dir

        if options.compressionType == dtcTarball and output == "":
          options.output = name & ".tar.gz"
        elif options.compressionType == dtcZipfile and output == "":
          options.output = name & ".zip"

        asuraScans(uri, tmpdir, options) # Get the files
      
      else:
        echo "Invalid formatting. Please use the URL of the episode 1 (not 0)!" 
        return

    of "reaper-scans.com":
      if uri.path.startswith("/manga/"): # Ensure first episode url instead of title page.
        let name = uri.path.split("/")[^2] # Extract name
        tmpdir = createTempDir(name & "_", "_downtoon") # Create named dir

        if options.compressionType == dtcTarball and output == "":
          options.output = name & ".tar.gz"
        elif options.compressionType == dtcZipfile and output == "":
          options.output = name & ".zip"
 
        reaperScans(uri, tmpdir, options) # Get the files

      else:
        echo "Invalid formatting. Please use the URL of the title page!" 
        return

    of "webtoons.com", "m.webtoons.com":

      echo "Webtoons already has it's own downloading function, please use that instead!"
      when defined(enableWebtoons):
        if uri.path.startswith("/en/"): # Ensure first episode url instead of title page.
          let name = uri.path.split("/")[^2] # Extract name
          tmpdir = createTempDir(name & "_", "_downtoon") # Create named dir

          if options.compressionType == dtcTarball and output == "":
            options.output = name & ".tar.gz"
          elif options.compressionType == dtcZipfile and output == "":
            options.output = name & ".zip"

          webToons(uri, tmpdir, options) # Get the files
 
        else:
          echo "Invalid formatting. Please use the URL of the title page!" 
          return

      else:
        return

    of "manhuaus.org":
      if uri.path.startswith("/manga/"): # Ensure first episode url instead of title page.
        let name = uri.path.split("/")[^2] # Extract name
        tmpdir = createTempDir(name & "_", "_downtoon") # Create named dir

        if options.compressionType == dtcTarball and output == "":
          options.output = name & ".tar.gz"
        elif options.compressionType == dtcZipfile and output == "":
          options.output = name & ".zip"

        manhuausOrg(uri, tmpdir, options) # Get the files

      else:
        echo "Invalid formatting. Please use the URL of the title page!" 
        return

    else:

      echo "We currently don't support this website."
      return

    # Compress and echo according to options
    if options.compressionType == dtcTarball:
      if not options.quiet:
        echo "Creating .tar.gz archive..."
      createTarball(tmpdir, options.output)
    elif options.compressionType == dtcZipfile:
      if not options.quiet:
        echo "Creating .zip archive..."
      createZipArchive(tmpdir, options.output)

    if not options.quiet:
      echo "Finished compressing at: " & options.output

  finally:
    # Cleanup
    removeDir(tmpdir)



when isMainModule:
  import cligen; dispatch downtoon, help={
    "quiet": "Whether to not provide console updates. Increases efficiency and speed.", 
    "url": "The url to the webcomic. \nAsurascans: episode 1 url, not epsiode 0", 
    "first": "The first chapter you want to download.",
    "last": "The last chapter you want to download. Downloads all inbetween first and last",
    "templateName": "HTML template name. \nbasic.nimja: Basic glue-together of the image frames (IOS safe). \nadvanced.nimja: Uses js and more advanced css to give a interactive and colorful display.",
    "compressionType": "Determines the compression type, dtcZipfile or dtcTarball",
    "fileFormat": "Determines the structure of the archive. \ndtDebug: All structures together. \ndtRelease: Html format useable for most devices. \ndtRaw: Raw images, most useful when trying to display them through another method, not reccommended for reading.",
    "noCompression": "If true, it won't compress the jpeg files, reducing loss of detail and making downtoon run faster.",
    # "optSpeed": "The default settings are optimized for output size, not speed. Enables noCompression (removes compression steps) and quiet."
  }