import std/re

proc webtoonDownloadSingle(client: var HttpClient, ourl, dir: string, o: Options): string =
    ## Download a single episode from reaper-scans.com

    var resp = client.get(ourl) # Download episode
    
    if resp.status != "301 Moved Permanently": # Enforce redirect
      raise newException(ValueError, "Request to page responded with " & resp.status)
    let url = "https://m.webtoons.com" & resp.headers["Location"]
  
    resp = client.get(url)
    if resp.status != "200 OK":
      raise newException(ValueError, "Request to page responded with " & resp.status)

    client.headers["Referer"] = url

    let html = resp.bodyStream.readAll()  

    let reg = re"https:\/\/mwebtoon-phinf\.pstatic\.net\/[0-9_]+\/.[^\/]+\/[0-9]+.[^\.]*\.jpg"

    let srcs = html.findAll(reg)

    var images = newSeq[string](0)

    if o.quiet:
      for i, src in srcs:
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
      for i, src in srcs:

        stdout.write("\rGathering: " & url & " [" & $(i + 1) & "/" & $srcs.len & "]")

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
      return renderChapterHtml(images, o.templateName, "webtoon")
    else:
      return ""




proc webToons(url: Uri, dir: string, o: Options) =
    ## Download from reaperscans from `uri` with options `o` to `dir`.

    let name = url.path.split("/")[^2]

    let baseUrl = $combine(url, parseUri("title/viewer?" & url.query & "&episode_no=$"))
    if not o.quiet:
      echo "Collecting: " & name
    var client = newHttpClient("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36", 0, 
                            headers = newHttpHeaders({"Referer": "https://m.webtoons.com/en/"}))

    for i in o.first..o.last:
      client.headers["Referer"] = "https://m.webtoons.com/en/"

      if o.fileFormat in {dtRaw, dtDebug}: # If raw mode, create folder to hold raw files
        createDir(dir & "/episodeRAW_" & $i)

      if not o.quiet:
        stdout.write "Gathering: " & baseUrl.replace("$", $i)
      let xml = client.webtoonDownloadSingle(baseUrl.replace("$", $i), dir & "/episodeRAW_" & $i, o) 

      if o.fileFormat in {dtRelease, dtDebug}:
        writeFile(dir & "/episode_" & $i & ".html", xml) # Write html file if release mode
