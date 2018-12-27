//
//  ZFView.m
//  OpenGL ES--002-glsl
//
//  Created by zhongding on 2018/12/27.
//

#import "ZFView.h"


#import <OpenGLES/ES3/gl.h>

@interface ZFView()
@property(strong ,nonatomic) CAEAGLLayer *eaglLayer;
@property(strong ,nonatomic) EAGLContext *context;

@property(assign ,nonatomic) GLuint renderBuffer;
@property(assign ,nonatomic) GLuint frameBuffer;

@property(assign ,nonatomic) GLint program;

@end
@implementation ZFView

- (void)layoutSubviews{
    [self setupLayer];
    [self setupContext];
    [self cleanBuffer];
    [self setupRenderBuffer];
    [self setupFrameBuffer];
    [self setupRender];
}

#pragma mark ***************** 6.开始绘制
- (void)setupRender{
    
    glClear(GL_COLOR_BUFFER_BIT);
    glClearColor(0.0f, 1.0f, 0.0f, 1.0f);

    CGFloat scale = [[UIScreen mainScreen] scale];
    glViewport(self.frame.origin.x * scale, self.frame.origin.y * scale, self.frame.size.width * scale, self.frame.size.height * scale);

    self.program = [self setupProgram];
    
    glLinkProgram(self.program);
    
    GLint linkStatus;
    glGetProgramiv(self.program, GL_LINK_STATUS, &linkStatus);
    
    if (linkStatus == GL_FALSE){
        
        char message[1024];
        glGetProgramInfoLog(self.program, sizeof(message), 0, &message[0]);
        NSString *err = [NSString stringWithUTF8String:message];
        NSLog(@"link err:%@",err);
        return;
    }
    
    glUseProgram(self.program);
    
    CGFloat size = 0.5f;

    GLfloat vertexs[] = {
//        1,-1,0,   1,1,
//        -1,1,0,   0,1,
//        -1,-1,0,  1,0,
//
//        1,-1,0,   1,0,
//        -1,1,0,   0,1,
//        1,1,0 ,    0,0
        
        size, -size, 0.0f,        1.0f, 1.0f, //右下
        -size, size, 0.0f,        0.0f, 0.0f, // 左上
        -size, -size, 0.0f,       0.0f, 1.0f, // 左下
        size, size, 0.0f,         1.0f, 0.0f, // 右上
        -size, size, 0.0f,        0.0f, 0.0f, // 左上
        size, -size, 0.0f,        1.0f, 1.0f, // 右下
    };
    
    
    GLuint attirBuffer;
    glGenBuffers(1, &attirBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, attirBuffer);
    //
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertexs), vertexs, GL_DYNAMIC_DRAW);
    
    //设置顶点坐标
    GLuint position = glGetAttribLocation(self.program, "position");
    glEnableVertexAttribArray(position);
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*5, NULL);
    
    //设置纹理坐标
    GLuint textCoordinate = glGetAttribLocation(self.program, "textCoordinate");
    glEnableVertexAttribArray(textCoordinate);
    glVertexAttribPointer(textCoordinate, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*5, (GLfloat*)NULL+3);
    
    
    [self setupTexture:@"test.jpg"];
    
    GLuint rotate = glGetUniformLocation(self.program, "rotateMatrix");
    
    //获取渲染的弧度
    float radians = 10 * 3.14159f / 180.0f;
    //求得弧度对于的sin\cos值
    float s = sin(radians);
    float c = cos(radians);
    
    //z轴旋转矩阵 参考3D数学第二节课的围绕z轴渲染矩阵公式
    //为什么和公司不一样？因为在3D课程中用的是横向量，在OpenGL ES用的是列向量
    GLfloat zRotation[16] = {
        c, -s, 0, 0,
        s, c, 0, 0,
        0, 0, 1.0, 0,
        0.0, 0, 0, 1.0
    };
    
    //设置旋转矩阵
    glUniformMatrix4fv(rotate, 1, GL_FALSE, (GLfloat *)&zRotation[0]);
    
    glDrawArrays(GL_TRIANGLES, 0, 6);
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)setupTexture:(NSString*)filename{
    
    CGImageRef image = [UIImage imageNamed:filename].CGImage;
    
    if (!image) {
        NSLog(@"获取纹理图片出错");
        return;
    }
    
    size_t width = CGImageGetWidth(image), height = CGImageGetHeight(image);
    
    GLubyte * data = (GLubyte*)calloc(width*height*4, sizeof(GLubyte));
    
    CGContextRef context = CGBitmapContextCreate(data, width, height, 8, width*4, CGImageGetColorSpace(image), kCGImageAlphaPremultipliedLast);
    
    CGContextDrawImage(context, CGRectMake(0, 0, (CGFloat)width, (CGFloat)height), image);
    
    CGContextRelease(context);
    
    //纹理设置
    
    glBindBuffer(GL_TEXTURE_2D, 0);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA,  (CGFloat)width, (CGFloat)height, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);
    
    glBindTexture(GL_TEXTURE_2D, 0);

    free(data);
}

-(GLint)setupProgram{
    NSString *verFile = [[NSBundle mainBundle] pathForResource:@"shaderv" ofType:@"vsh"];
    NSString *fragFile = [[NSBundle mainBundle] pathForResource:@"shaderf" ofType:@"fsh"];
    
    GLuint vertexShader, fragmentShader;
    [self compileShader:&vertexShader type:GL_VERTEX_SHADER file:verFile];
    [self compileShader:&fragmentShader type:GL_FRAGMENT_SHADER file:fragFile];
    
    GLint program = glCreateProgram();
    
    glAttachShader(program, vertexShader);
    glAttachShader(program, fragmentShader);

    glDeleteShader(vertexShader);
    glDeleteShader(fragmentShader);
    
    return program;
}

- (void)compileShader:(GLuint*)shader type:(GLenum)type file:(NSString *)file{
    
    NSString *content = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];
    const GLchar *source = (GLchar*)[content UTF8String];
    
    
    *shader = glCreateShader(type);
    
    glShaderSource(*shader, 1, &source, NULL);
    
    glCompileShader(*shader);
}

#pragma mark ***************** 5.创建framebuffer
- (void)setupFrameBuffer{
    glGenFramebuffers(1, &_frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderBuffer);
}

#pragma mark ***************** 4.创建renderbuffer
- (void)setupRenderBuffer{
    
    glGenRenderbuffers(1, &_renderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
    
    [self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.eaglLayer];
}

#pragma mark ***************** 3.清除缓冲区
- (void)cleanBuffer{
    glDeleteBuffers(1, &_renderBuffer);
    _renderBuffer = 0;
    
    glDeleteBuffers(1, &_frameBuffer);
    _frameBuffer = 0;
}

#pragma mark ***************** 2.创建上下文
- (void)setupContext{
    self.context = [[EAGLContext alloc] initWithAPI:(kEAGLRenderingAPIOpenGLES3)];
    //是否创建成功
    if (!self.context) {
        NSLog(@"contexto init failed");
        return;
    }
    [EAGLContext setCurrentContext:self.context];
}

#pragma mark ***************** 1。创建图层
- (void)setupLayer{
    self.eaglLayer = (CAEAGLLayer*)self.layer;
    //设置图层不透明
    self.eaglLayer.opaque = YES;
    
    [self setContentScaleFactor:[[UIScreen mainScreen]scale]];

    self.eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:false],kEAGLDrawablePropertyRetainedBacking,kEAGLColorFormatRGBA8,kEAGLDrawablePropertyColorFormat, nil];
}

+ (Class)layerClass{
    return [CAEAGLLayer class];
}

@end
