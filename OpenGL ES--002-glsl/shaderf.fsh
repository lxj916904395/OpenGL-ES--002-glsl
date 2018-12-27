
varying lowp vec2 varyTextCoor;//从顶点着色器传递给片元着色器的变量，变量声明必须一致

//2d纹理贴图
uniform sampler2D colorMap;


void main(){
    /*
     gl_FragColor：片元着色器的内建变量，必选赋值，香色才能显示颜色、纹理
     */
    gl_FragColor = texture2D(colorMap,varyTextCoor);
}


