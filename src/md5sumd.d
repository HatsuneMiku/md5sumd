/*
  md5sumd.d

  dmd -version=Unicode -run md5sumd.d
*/

import std.windows.charset;
import std.utf;
import std.stdio;
import std.string;

int main(string[] args)
{
  foreach(int i, string arg; args){
    writefln("arg[%d] = '%s'", i, arg);
  }
  return 0;
}
