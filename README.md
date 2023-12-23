# DownToon
A webcomic downloading cli tool, allowing users to read their favorite comics offline!

## Installation
### Linux
Install `install.sh` and run it. Follow furthur instructions.
### Any other device
Install nim and run `nimble install https://github.com/thatrandomperson5/DownToon.git@#main`

## Usage
```
Usage:
  downtoon [REQUIRED,optional-params] 
Main command
Options:
  -h, --help                                                       print this cligen-erated help
  --help-syntax                                                    advanced: prepend,plurals,..
  -o=, --output=           string                      ""          set output
  -q, --quiet              bool                        false       Whether to not provide console
                                                                   updates. Increases efficiency and
                                                                   speed.
  -n, --noCompression      bool                        false       If true, it won't compress the jpeg
                                                                   files, reducing loss of detail and
                                                                   making downtoon run faster.
  -f=, --first=            int                         1           The first chapter you want to
                                                                   download.
  -l=, --last=             int                         REQUIRED    The last chapter you want to
                                                                   download. Downloads all inbetween
                                                                   first and last
  -u=, --url=              string                      REQUIRED    The url to the webcomic. 
                                                                   Asurascans: first chapter url
  -t=, --templateName=     string                      "basic"     HTML template name. 
                                                                   basic.nimja: Basic glue-together of the image frames (IOS safe). 
                                                                   advanced.nimja: Uses js and more advanced css to give a interactive and colorful display.
  -c=, --compressionType=  DownToonCompressionFormats  dtcTarball  Determines the compression type,
                                                                   dtcZipfile or dtcTarball
  --fileFormat=            DownToonFileFormat          dtRelease   Determines the structure of the archive. 
                                                                   dtDebug: All structures together. 
                                                                   dtRelease: Html format useable for most devices. 
                                                                   dtRaw: Raw images, most useful when trying to display them through another method, not reccommended for reading.

```

## Support


| Website          | Supported | Details                                     | Speed       | Output Size         | Shared Libraries Required |
|------------------|-----------|---------------------------------------------|-------------|---------------------|---------------------------|
| AsuraScans/Toons | ✅      | N/A                                         | Medium-Fast | Small (27 M)        | FreeImage, OpenSSL        |
| ReaperScans      | ✅      | N/A                                         | Fast        | Small (22 M)        | FreeImage, OpenSSL        |
| Webtoons         | 🔶      | Needs a special binary (`-d:enableWebtoons`), not sure if i should fully support.| Medium-Slow | Medium-Small (34 M) | FreeImage, OpenSSL, PCRE  |

## TODO
* [X] First Release
* [X] Install Script
* [ ] Database logging / sizes
* [ ] GUI & Desktop App
* [ ] Support More Sites