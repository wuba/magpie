
import '../lib/executable.dart' as executable;
const magpie = r'''
                                                
 /'\_/`\                           __           
/\      \     __       __   _____ /\_\     __   
\ \ \__\ \  /'__`\   /'_ `\/\ '__`\/\ \  /'__`\ 
 \ \ \_/\ \/\ \L\.\_/\ \L\ \ \ \L\ \ \ \/\  __/ 
  \ \_\\ \_\ \__/.\_\ \____ \ \ ,__/\ \_\ \____\
   \/_/ \/_/\/__/\/_/\/___L\ \ \ \/  \/_/\/____/
                       /\____/\ \_\             
                       \_/__/  \/_/             
''';
void main(List<String> args) {
  print(magpie);
  var list = args;
  if (args.length == 0) {
    list = ["service"];
  }
  executable.main(list);
}