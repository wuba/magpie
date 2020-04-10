import 'dart:convert';

class ResponseBean<ValueType> {
  int code; // 0失败,1成功
  String msg; //失败信息
  ValueType data;

  ResponseBean(this.data, {this.code = 1, this.msg = ''});

  ResponseBean.error(this.data, {this.msg = ''}) : this.code = 0;

  @override
  String toString() {
    return jsonEncode({'code': code, 'msg': msg, 'data': data});
  }
}
