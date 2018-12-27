
attribute vec4 position;//顶点位置
attribute vec2 textCoordinate;//纹理坐标
uniform mat4 rotateMatrix;//旋转z矩阵

varying lowp vec2 varyTextCoor;//传递给片元着色器的变量

void main(){
    
    varyTextCoor = textCoordinate;
    
    vec4 pos = position;
    //旋转矩阵与顶点坐标相乘,得到新的顶点矩阵
    pos = pos * rotateMatrix;
    
    /*
     gl_Position:顶点着色器的内建变量，必须赋值
     */
    gl_Position = pos;
}
