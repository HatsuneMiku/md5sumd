/*
  md5sumd.d

  dmd -version=Unicode -run md5sumd.d md5sumd.d

  std.md5 is scheduled for deprecation. Please use std.digest.md instead
*/

// private import win32.core;
private import std.exception;
private import std.windows.charset;
private import std.utf;
private import std.stdio;
private import std.string;
private import std.conv;
private import std.array;
private import std.path;
private import std.file;
private import std.socket;
private import std.datetime;
private import core.time;

private const size_t bufsiz = 1024 * 4096;

string md5sumf(string filename) // std.stream.File 日本語ファイル名扱える
{
  import std.stream;
  File fp = new File(filename);
  scope(exit) fp.close();

  import std.digest.md;
  MD5Digest md5 = new MD5Digest();
  ubyte[] buffer = new ubyte[bufsiz];
  size_t n;
  while((n = fp.read(buffer)) > 0) md5.put(buffer[0..n]);
  return toHexString(md5.finish()).toLower();
}

/*
string md5sumf(string filename) // std.stream.File 日本語ファイル名扱える
{
  import std.stream;
  // File fp = new File(filename);
  // BufferedFile fp = new BufferedFile(new File(filename), bufsiz);
  BufferedFile fp = new BufferedFile(filename, FileMode.In, bufsiz);
  scope(exit) fp.close();

  import std.md5;
  ubyte[16] digest;
  MD5_CTX md5;
  md5.start();
  ubyte[] buffer = new ubyte[bufsiz];
  size_t n;
  while((n = fp.read(buffer)) > 0) md5.update(buffer[0..n]);
  md5.finish(digest);
  return digestToString(digest).toLower();
}
*/

/*
string md5sumf(string filename) // std.stdio.File 日本語ファイル名扱えない
{
  File fp = File(filename);
  scope(exit) fp.close();

  import std.md5;
  ubyte[16] digest;
  MD5_CTX md5;
  md5.start();
  foreach(ubyte[] buffer; chunks(fp, bufsiz)) md5.update(buffer);
  md5.finish(digest);
  return digestToString(digest).toLower();
}
*/

/*
string md5sumf(string filename) // std.stdio.File 日本語ファイル名扱えない
{
  import std.md5;
  ubyte[16] digest;
  MD5_CTX md5;
  md5.start();
  foreach(ubyte[] buffer; File(filename).byChunk(bufsiz)) md5.update(buffer);
  md5.finish(digest);
  return digestToString(digest).toLower();
}
*/

/*
string md5sumf(string filename) // std.stdio.File 日本語ファイル名扱えない
{
  import std.digest.md;
  MD5 md5;
  md5.start();
  foreach(ubyte[] buffer; File(filename).byChunk(bufsiz)) md5.put(buffer);
  return toHexString(cast(ubyte[])md5.finish()).toLower();
}
*/

/*
string md5sumf(string filename) // std.stdio.File 日本語ファイル名扱えない
{
  import std.digest.md;
  MD5Digest md5 = new MD5Digest();
  foreach(ubyte[] buffer; File(filename).byChunk(bufsiz)) md5.put(buffer);
  return toHexString(md5.finish()).toLower();
}
*/

void md5sumr(string p)
{
  try{
    if(!exists(p)){
      writefln("not exist: %s", p);
      return;
    }
    if(!isDir(p)){
      writefln("%s %s", md5sumf(p), p);
    }else{
      /*
        注: SpanMode.depth だと subdir\filename の後に subdir が表示される。
        SpanMode.breadth を使うと dirName が先に取り出せるので有利に思えるが、
        python の os.walk と違って file と directory が混在するため、
        subdir から戻った後に表示される元の階層の file が subdir と錯覚する。
        os.walk のような順 (directory だけ先に処理) で表示したい場合、
        自分で isDir に応じて再帰関数を作ることになるが、上の問題は解決しない。
        また、再帰関数を使うとスタックの心配も出て来るのでメリットが殆どない。
        結論: SpanMode.depth でも SpanMode.breadth でもどちらを使っても同じで、
        dirName を毎回チェックして、前回と異なる場合のみ表示するタイプで実装。
      */
      string prev = p;
      writefln("dir: %s", prev);
      foreach(DirEntry e; dirEntries(p, SpanMode.depth)){ // SpanMode.breadth
        string f = e.name;
        if(e.isSymlink) writefln("sym: %s", f);
        else if(e.isDir) continue; // writefln("dir: %s", f); // 上記注
        else{
          string d = dirName(f);
          if(d != prev){
            prev = d;
            writefln("dir: %s", prev);
          }
          string b = baseName(f);
          writefln("%s %-15s %12d %s",
            md5sumf(f), e.timeLastModified.toISOString()[0..15], e.size, b);
        }
      }
    }
  }catch(FileException e){
    // writef() supports only UTF-8
    // MessageBoxW(null, e.msg.toUTF16z(), "FileException", MB_OK);
    printf("*** FileException: %d\n %s\n", e.errno, e.msg.toMBSz());
  }catch(DateTimeException e){
    writefln("*** DateTimeException: %s", e.msg);
  }
}

int main(string[] args)
{
  if(args.length < 2){
    writefln("Usage: %s (path or file)", args[0]);
    return 1;
  }
  foreach(int i, string arg; args){
    writefln("arg[%d] = '%s'", i, arg);
    md5sumr(buildNormalizedPath(absolutePath(arg)));
  }
  return 0;
}
