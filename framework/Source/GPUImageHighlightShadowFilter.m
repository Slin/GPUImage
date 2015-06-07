#import "GPUImageHighlightShadowFilter.h"

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUImageHighlightShadowFragmentShaderString = SHADER_STRING
(
uniform sampler2D inputImageTexture;
varying highp vec2 textureCoordinate;
 
uniform highp float shadows;
uniform highp float highlights;

 const mediump vec3 luminanceWeighting = vec3(0.2126, 0.7152, 0.0722);

void main()
{
	highp vec4 source = texture2D(inputImageTexture, textureCoordinate);
	highp float luminance = dot(source.rgb, luminanceWeighting);

	highp float shadowDiff = clamp(0.5-luminance, 0.0, 0.5);
	highp float shadowFactor;
	
	if(shadows < 0.0)
	{
		shadowFactor = -sqrt(-4.0*shadowDiff*shadowDiff+4.0*shadowDiff)*0.5;
	}
	else
	{
		shadowFactor = (sqrt(1.0-4.0*shadowDiff*shadowDiff)-1.0)*0.5;
	}
	
	shadowFactor = mix(-shadowDiff, shadowFactor, abs(shadows));
	highp float shadow = shadowDiff+shadowFactor;
	
	
	highp float highlightDiff = clamp(luminance-0.5, 0.0, 0.5);
	highp float highlightFactor;
 
	if(highlights > 0.0)
	{
		highlightFactor = sqrt(-4.0*highlightDiff*highlightDiff+4.0*highlightDiff)*0.5;
	}
	else
	{
		highlightFactor = (-sqrt(1.0-4.0*highlightDiff*highlightDiff)+1.0)*0.5;
	}
	
	highlightFactor = mix(highlightDiff, highlightFactor, abs(highlights));
	highp float highlight = -highlightDiff+highlightFactor;
	lowp vec3 result = clamp(luminance + shadow + highlight, 0.0, 1.0) * (source.rgb/luminance);

	gl_FragColor = vec4(result.rgb, source.a);
}
);
#else
NSString *const kGPUImageHighlightShadowFragmentShaderString = SHADER_STRING
(
 uniform sampler2D inputImageTexture;
 varying vec2 textureCoordinate;
 
 uniform float shadows;
 uniform float highlights;
 
 const vec3 luminanceWeighting = vec3(0.2126, 0.7152, 0.0722);
 
 void main()
 {
	vec4 source = texture2D(inputImageTexture, textureCoordinate);
	float luminance = dot(source.rgb, luminanceWeighting);
    
	float shadow = clamp((pow(luminance, 1.0/(shadows+1.0)) + (-0.76)*pow(luminance, 2.0/(shadows+1.0))) - luminance, 0.0, 1.0);
	float highlight = clamp((1.0 - (pow(1.0-luminance, 1.0/(2.0-highlights)) + (-0.8)*pow(1.0-luminance, 2.0/(2.0-highlights)))) - luminance, -1.0, 0.0);
	vec3 result = vec3(0.0, 0.0, 0.0) + ((luminance + shadow + highlight) - 0.0) * ((source.rgb - vec3(0.0, 0.0, 0.0))/(luminance - 0.0));
    
	gl_FragColor = vec4(result.rgb, source.a);
 }
);
#endif

@implementation GPUImageHighlightShadowFilter

@synthesize shadows = _shadows;
@synthesize highlights = _highlights;

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageHighlightShadowFragmentShaderString]))
    {
		return nil;
    }
    
    shadowsUniform = [filterProgram uniformIndex:@"shadows"];
	highlightsUniform = [filterProgram uniformIndex:@"highlights"];
	
    self.shadows = 0.0;
	self.highlights = 0.0;

    return self;
}

#pragma mark -
#pragma mark Accessors

- (void)setShadows:(CGFloat)newValue;
{
    _shadows = newValue;

    [self setFloat:_shadows forUniform:shadowsUniform program:filterProgram];
}

- (void)setHighlights:(CGFloat)newValue;
{
	_highlights = newValue;

    [self setFloat:_highlights forUniform:highlightsUniform program:filterProgram];
}

@end

