﻿float3 compNormalDirection(float2 Set_UV0, float3x3 tangentTransform) {
    //v.2.0.6
    //float3 _NormalMap_var = UnpackNormal(tex2D(_NormalMap,TRANSFORM_TEX(Set_UV0, _NormalMap)));
    float3 _NormalMap_var = UnpackScaleNormal(tex2D(_NormalMap, TRANSFORM_TEX(Set_UV0, _NormalMap)), _BumpScale);
    float3 normalLocal = _NormalMap_var.rgb;
    float3 normalDirection = normalize(mul(normalLocal, tangentTransform)); // Perturbed normals
    return normalDirection;
}

float clipping(float2 Set_UV0, float4 _MainTex_var)
{
    //v.2.0.4
#ifdef _IS_CLIPPING_MODE
//DoubleShadeWithFeather_Clipping
    float4 _ClippingMask_var = tex2D(_ClippingMask, TRANSFORM_TEX(Set_UV0, _ClippingMask));
    float Set_Clipping = saturate((lerp(_ClippingMask_var.r, (1.0 - _ClippingMask_var.r), _Inverse_Clipping) + _Clipping_Level));
    clip(Set_Clipping - 0.5);

    return 0;
#elif _IS_CLIPPING_TRANSMODE
//DoubleShadeWithFeather_TransClipping
    float4 _ClippingMask_var = tex2D(_ClippingMask, TRANSFORM_TEX(Set_UV0, _ClippingMask));
    float Set_MainTexAlpha = _MainTex_var.a;
    float _IsBaseMapAlphaAsClippingMask_var = lerp(_ClippingMask_var.r, Set_MainTexAlpha, _IsBaseMapAlphaAsClippingMask);
    float _Inverse_Clipping_var = lerp(_IsBaseMapAlphaAsClippingMask_var, (1.0 - _IsBaseMapAlphaAsClippingMask_var), _Inverse_Clipping);
    float Set_Clipping = saturate((_Inverse_Clipping_var + _Clipping_Level));
    clip(Set_Clipping - 0.5);

    return _Inverse_Clipping_var;
#elif _IS_CLIPPING_OFF
//DoubleShadeWithFeather
    return 0;
#endif
}

float3 compLightDirection(VertexOutput i)
{
    //v.2.0.4
#ifdef _IS_PASS_FWDBASE

    float3 defaultLightDirection = normalize(UNITY_MATRIX_V[2].xyz + UNITY_MATRIX_V[1].xyz);
    //v.2.0.5
    float3 customLightDirection = normalize(mul(unity_ObjectToWorld, float4(((float3(1.0, 0.0, 0.0)*_Offset_X_Axis_BLD * 10) + (float3(0.0, 1.0, 0.0)*_Offset_Y_Axis_BLD * 10) + (float3(0.0, 0.0, -1.0)*lerp(-1.0, 1.0, _Inverse_Z_Axis_BLD))), 0)).xyz);
    float3 lightDirection = normalize(lerp(defaultLightDirection, _WorldSpaceLightPos0.xyz, any(_WorldSpaceLightPos0.xyz)));
    lightDirection = lerp(lightDirection, customLightDirection, _Is_BLD);
#elif _IS_PASS_FWDDELTA
    float3 lightDirection = normalize(lerp(_WorldSpaceLightPos0.xyz, _WorldSpaceLightPos0.xyz - i.posWorld.xyz, _WorldSpaceLightPos0.w));
#endif

    return lightDirection;
}

float3 compLightColor(VertexOutput i, float3 lightDirection, float3 normalDirection, float attenuation)
{
    //v.2.0.4
#ifdef _IS_PASS_FWDBASE
    //v.2.0.5
    float3 defaultLightColor = saturate(max(half3(0.05, 0.05, 0.05)*_Unlit_Intensity, max(ShadeSH9(half4(0.0, 0.0, 0.0, 1.0)), ShadeSH9(half4(0.0, -1.0, 0.0, 1.0)).rgb)*_Unlit_Intensity));
    //v.2.0.5: 
    float3 lightColor = lerp(max(defaultLightColor, _LightColor0.rgb), max(defaultLightColor, saturate(_LightColor0.rgb)), _Is_Filter_LightColor);
#elif _IS_PASS_FWDDELTA
    //v.2.0.5: 
    float3 addPassLightColor = (0.5*dot(lerp(i.normalDir, normalDirection, _Is_NormalMapToBase), lightDirection) + 0.5) * _LightColor0.rgb * attenuation;
    float pureIntencity = max(0.001, (0.299*_LightColor0.r + 0.587*_LightColor0.g + 0.114*_LightColor0.b));
    float3 lightColor = max(0, lerp(addPassLightColor, lerp(0, min(addPassLightColor, addPassLightColor / pureIntencity), _WorldSpaceLightPos0.w), _Is_Filter_LightColor));
#endif

    return lightColor;
}

float3 compBaseColor(
    float4 _MainTex_var, float2 Set_UV0,
    float3 Set_LightColor, float _HalfLambert_var, float4 _Set_1st_ShadePosition_var,
    float _SystemShadowsLevel_var, float Set_FinalShadowMask)
{
    float3 Set_BaseColor = _BaseColor.rgb * _MainTex_var.rgb;
    Set_BaseColor = lerp(Set_BaseColor, Set_BaseColor * Set_LightColor, _Is_LightColor_Base);

    //v.2.0.5
    float4 _1st_ShadeMap_var = tex2D(_1st_ShadeMap, TRANSFORM_TEX(Set_UV0, _1st_ShadeMap));
    _1st_ShadeMap_var = lerp(_1st_ShadeMap_var, _MainTex_var, _Use_BaseAs1st);
    float3 Set_1st_ShadeColor = _1st_ShadeColor.rgb*_1st_ShadeMap_var.rgb;
    Set_1st_ShadeColor = lerp(Set_1st_ShadeColor, Set_1st_ShadeColor*Set_LightColor, _Is_LightColor_1st_Shade);

    //v.2.0.5
    float4 _2nd_ShadeMap_var = tex2D(_2nd_ShadeMap, TRANSFORM_TEX(Set_UV0, _2nd_ShadeMap));
    _2nd_ShadeMap_var = lerp(_2nd_ShadeMap_var, _1st_ShadeMap_var, _Use_1stAs2nd);
    float3 Set_2nd_ShadeColor = _2nd_ShadeColor.rgb*_2nd_ShadeMap_var.rgb;
    Set_2nd_ShadeColor = lerp(Set_2nd_ShadeColor, Set_2nd_ShadeColor*Set_LightColor, _Is_LightColor_2nd_Shade);

    float4 _Set_2nd_ShadePosition_var = tex2D(_Set_2nd_ShadePosition, TRANSFORM_TEX(Set_UV0, _Set_2nd_ShadePosition));

    //Composition: 3 Basic Colors as Set_FinalBaseColor
    float shadeStepSub = _ShadeColor_Step - _1st2nd_Shades_Feather;
    float ratio = 1.0 + (_HalfLambert_var - shadeStepSub) * (-_Set_2nd_ShadePosition_var.r) / _1st2nd_Shades_Feather;
    ratio = saturate(ratio);
    float3 Set_1st2nd_ShadeColor = lerp(Set_1st_ShadeColor, Set_2nd_ShadeColor, ratio);
    float3 Set_FinalBaseColor = lerp(Set_BaseColor, Set_1st2nd_ShadeColor, Set_FinalShadowMask); // Final Color

    return Set_FinalBaseColor;
}

float3 compHighColor(
    VertexOutput i, float2 Set_UV0, float3 normalDirection, float3 halfDirection,
    float3 Set_LightColor, float3 Set_FinalBaseColor, float Set_FinalShadowMask)
{
    float4 _Set_HighColorMask_var = tex2D(_Set_HighColorMask, TRANSFORM_TEX(Set_UV0, _Set_HighColorMask));
    float _Specular_var = 0.5*dot(halfDirection, lerp(i.normalDir, normalDirection, _Is_NormalMapToHighColor)) + 0.5; //  Specular                
    float _TweakHighColorMask_var = (saturate((_Set_HighColorMask_var.g + _Tweak_HighColorMaskLevel))*lerp((1.0 - step(_Specular_var, (1.0 - pow(_HighColor_Power, 5)))), pow(_Specular_var, exp2(lerp(11, 1, _HighColor_Power))), _Is_SpecularToHighColor));
    float4 _HighColor_Tex_var = tex2D(_HighColor_Tex, TRANSFORM_TEX(Set_UV0, _HighColor_Tex));
    float3 _HighColor_var = (lerp((_HighColor_Tex_var.rgb*_HighColor.rgb), ((_HighColor_Tex_var.rgb*_HighColor.rgb)*Set_LightColor), _Is_LightColor_HighColor)*_TweakHighColorMask_var);

    //Composition: 3 Basic Colors and HighColor as Set_HighColor
    float3 maskedBase = saturate(Set_FinalBaseColor - _TweakHighColorMask_var);
    fixed baseRate = lerp(_Is_BlendAddToHiColor, 1.0, _Is_SpecularToHighColor);
    float3 base = lerp(maskedBase, Set_FinalBaseColor, baseRate);

    float3 maskedHigh = _HighColor_var*((1.0 - Set_FinalShadowMask) + (Set_FinalShadowMask*_TweakHighColorOnShadow));
    float3 high = lerp(_HighColor_var, maskedHigh, _Is_UseTweakHighColorOnShadow);

    float3 Set_HighColor = base + high;

    return Set_HighColor;
}

float3 compRimLight(
    VertexOutput i, float2 Set_UV0, float3 Set_LightColor,
    float3 viewDirection, float3 normalDirection, float3 lightDirection)
{
    float4 _Set_RimLightMask_var = tex2D(_Set_RimLightMask, TRANSFORM_TEX(Set_UV0, _Set_RimLightMask));
    float3 _Is_LightColor_RimLight_var = lerp(_RimLightColor.rgb, (_RimLightColor.rgb*Set_LightColor), _Is_LightColor_RimLight);
    float _RimArea_var = (1.0 - dot(lerp(i.normalDir, normalDirection, _Is_NormalMapToRimLight), viewDirection));
    float _RimLightPower_var = pow(_RimArea_var, exp2(lerp(3, 0, _RimLight_Power)));
    float _Rimlight_InsideMask_var = saturate(lerp((0.0 + ((_RimLightPower_var - _RimLight_InsideMask) * (1.0 - 0.0)) / (1.0 - _RimLight_InsideMask)), step(_RimLight_InsideMask, _RimLightPower_var), _RimLight_FeatherOff));
    float _VertHalfLambert_var = 0.5*dot(i.normalDir, lightDirection) + 0.5;
    float3 _LightDirection_MaskOn_var = lerp((_Is_LightColor_RimLight_var*_Rimlight_InsideMask_var), (_Is_LightColor_RimLight_var*saturate((_Rimlight_InsideMask_var - ((1.0 - _VertHalfLambert_var) + _Tweak_LightDirection_MaskLevel)))), _LightDirection_MaskOn);
    float _ApRimLightPower_var = pow(_RimArea_var, exp2(lerp(3, 0, _Ap_RimLight_Power)));
    float3 Set_RimLight = (saturate((_Set_RimLightMask_var.g + _Tweak_RimLightMaskLevel))*lerp(_LightDirection_MaskOn_var, (_LightDirection_MaskOn_var + (lerp(_Ap_RimLightColor.rgb, (_Ap_RimLightColor.rgb*Set_LightColor), _Is_LightColor_Ap_RimLight)*saturate((lerp((0.0 + ((_ApRimLightPower_var - _RimLight_InsideMask) * (1.0 - 0.0)) / (1.0 - _RimLight_InsideMask)), step(_RimLight_InsideMask, _ApRimLightPower_var), _Ap_RimLight_FeatherOff) - (saturate(_VertHalfLambert_var) + _Tweak_LightDirection_MaskLevel))))), _Add_Antipodean_RimLight));

    return Set_RimLight;
}

struct CameraParam
{
    fixed _sign_Mirror;
    float3 _Camera_Right;
    float _Camera_Roll;
    fixed _Camera_Dir;
};

CameraParam compCameraParam(VertexOutput i)
{
    //v.2.0.6 : CameraRolling Stabilizer
    //鏡スクリプト判定：_sign_Mirror = -1 なら、鏡の中と判定.
    //v.2.0.7
    fixed _sign_Mirror = i.mirrorFlag;
    //
    float3 _Camera_Right = UNITY_MATRIX_V[0].xyz;
    float3 _Camera_Front = UNITY_MATRIX_V[2].xyz;
    float3 _Up_Unit = float3(0, 1, 0);
    float3 _Right_Axis = cross(_Camera_Front, _Up_Unit);
    //鏡の中なら反転.
    if(_sign_Mirror < 0){
        _Right_Axis = -1 * _Right_Axis;
        _Rotate_MatCapUV = -1 * _Rotate_MatCapUV;
    }else{
        _Right_Axis = _Right_Axis;
    }
    float _Camera_Right_Magnitude = sqrt(_Camera_Right.x*_Camera_Right.x + _Camera_Right.y*_Camera_Right.y + _Camera_Right.z*_Camera_Right.z);
    float _Right_Axis_Magnitude = sqrt(_Right_Axis.x*_Right_Axis.x + _Right_Axis.y*_Right_Axis.y + _Right_Axis.z*_Right_Axis.z);
    float _Camera_Roll_Cos = dot(_Right_Axis, _Camera_Right) / (_Right_Axis_Magnitude * _Camera_Right_Magnitude);
    float _Camera_Roll = acos(clamp(_Camera_Roll_Cos, -1, 1));
    fixed _Camera_Dir = _Camera_Right.y < 0 ? -1 : 1;

    CameraParam dst = { _sign_Mirror, _Camera_Right, _Camera_Roll, _Camera_Dir };
    return dst;
}

float3 compMatCap(
    VertexOutput i, float3x3 tangentTransform, float3 viewDirection, float2 Set_UV0,
    float3 Set_LightColor, float Set_FinalShadowMask, float3 Set_HighColor, float3 Set_RimLight, float3 _RimLight_var,
    CameraParam cameraParam)
{
    float _Rot_MatCapUV_var_ang = (_Rotate_MatCapUV*3.141592654) - cameraParam._Camera_Dir * cameraParam._Camera_Roll*_CameraRolling_Stabilizer;
    //v.2.0.7
    float2 _Rot_MatCapNmUV_var = RotateUV(Set_UV0, (_Rotate_NormalMapForMatCapUV*3.141592654), float2(0.5, 0.5), 1.0);
    //V.2.0.6
    float3 _NormalMapForMatCap_var = UnpackScaleNormal(tex2D(_NormalMapForMatCap, TRANSFORM_TEX(_Rot_MatCapNmUV_var, _NormalMapForMatCap)), _BumpScaleMatcap);
    //v.2.0.5: MatCap with camera skew correction
    float3 viewNormal = (mul(UNITY_MATRIX_V, float4(lerp(i.normalDir, mul(_NormalMapForMatCap_var.rgb, tangentTransform).rgb, _Is_NormalMapForMatCap), 0))).rgb;
    float3 NormalBlend_MatcapUV_Detail = viewNormal.rgb * float3(-1, -1, 1);
    float3 NormalBlend_MatcapUV_Base = (mul(UNITY_MATRIX_V, float4(viewDirection, 0)).rgb*float3(-1, -1, 1)) + float3(0, 0, 1);
    float3 noSknewViewNormal = NormalBlend_MatcapUV_Base * dot(NormalBlend_MatcapUV_Base, NormalBlend_MatcapUV_Detail) / NormalBlend_MatcapUV_Base.b - NormalBlend_MatcapUV_Detail;
    float2 _ViewNormalAsMatCapUV = (lerp(noSknewViewNormal, viewNormal, _Is_Ortho).rg*0.5) + 0.5;
    //v.2.0.7
    float2 _Rot_MatCapUV_var = RotateUV((0.0 + ((_ViewNormalAsMatCapUV - (0.0 + _Tweak_MatCapUV)) * (1.0 - 0.0)) / ((1.0 - _Tweak_MatCapUV) - (0.0 + _Tweak_MatCapUV))), _Rot_MatCapUV_var_ang, float2(0.5, 0.5), 1.0);
    //鏡の中ならUV左右反転.
    if(cameraParam._sign_Mirror < 0){
        _Rot_MatCapUV_var.x = 1 - _Rot_MatCapUV_var.x;
    }else{
        _Rot_MatCapUV_var = _Rot_MatCapUV_var;
    }
    //v.2.0.6 : LOD of Matcap
    float4 _MatCap_Sampler_var = tex2Dlod(_MatCap_Sampler, float4(TRANSFORM_TEX(_Rot_MatCapUV_var, _MatCap_Sampler), 0.0, _BlurLevelMatcap));
    //
    //MatcapMask
    float4 _Set_MatcapMask_var = tex2D(_Set_MatcapMask, TRANSFORM_TEX(Set_UV0, _Set_MatcapMask));
    float _Tweak_MatcapMaskLevel_var = saturate(lerp(_Set_MatcapMask_var.g, (1.0 - _Set_MatcapMask_var.g), _Inverse_MatcapMask) + _Tweak_MatcapMaskLevel);
    //
    float3 _Is_LightColor_MatCap_var = lerp((_MatCap_Sampler_var.rgb*_MatCapColor.rgb), ((_MatCap_Sampler_var.rgb*_MatCapColor.rgb)*Set_LightColor), _Is_LightColor_MatCap);
    //v.2.0.6 : ShadowMask on Matcap in Blend mode : multiply
    float3 Set_MatCap = lerp(_Is_LightColor_MatCap_var, (_Is_LightColor_MatCap_var*((1.0 - Set_FinalShadowMask) + (Set_FinalShadowMask*_TweakMatCapOnShadow)) + lerp(Set_HighColor*Set_FinalShadowMask*(1.0 - _TweakMatCapOnShadow), float3(0.0, 0.0, 0.0), _Is_BlendAddToMatCap)), _Is_UseTweakMatCapOnShadow);
    //
    //Composition: RimLight and MatCap as finalColor
    //Broke down finalColor composition
    float3 matCapColorOnAddMode = _RimLight_var + Set_MatCap * _Tweak_MatcapMaskLevel_var;
    float _Tweak_MatcapMaskLevel_var_MultiplyMode = _Tweak_MatcapMaskLevel_var * lerp(1.0, (1.0 - (Set_FinalShadowMask)*(1.0 - _TweakMatCapOnShadow)), _Is_UseTweakMatCapOnShadow);
    float3 matCapColorOnMultiplyMode = Set_HighColor * (1 - _Tweak_MatcapMaskLevel_var_MultiplyMode) + Set_HighColor * Set_MatCap*_Tweak_MatcapMaskLevel_var_MultiplyMode + lerp(float3(0, 0, 0), Set_RimLight, _RimLight);
    float3 matCapColorFinal = lerp(matCapColorOnMultiplyMode, matCapColorOnAddMode, _Is_BlendAddToMatCap);

    return matCapColorFinal;
}

void compEmissive(VertexOutput i, float3 viewDirection, float3 normalDirection, float2 Set_UV0, CameraParam cameraParam)
{
//v.2.0.7
#ifdef _EMISSIVE_SIMPLE
    float4 _Emissive_Tex_var = tex2D(_Emissive_Tex, TRANSFORM_TEX(Set_UV0, _Emissive_Tex));
    float emissiveMask = _Emissive_Tex_var.a;
    emissive = _Emissive_Tex_var.rgb * _Emissive_Color.rgb * emissiveMask;
#elif _EMISSIVE_ANIMATION
    //v.2.0.7 Calculation View Coord UV for Scroll 
    float3 viewNormal_Emissive = (mul(UNITY_MATRIX_V, float4(i.normalDir, 0))).xyz;
    float3 NormalBlend_Emissive_Detail = viewNormal_Emissive * float3(-1, -1, 1);
    float3 NormalBlend_Emissive_Base = (mul(UNITY_MATRIX_V, float4(viewDirection, 0)).xyz*float3(-1, -1, 1)) + float3(0, 0, 1);
    float3 noSknewViewNormal_Emissive = NormalBlend_Emissive_Base * dot(NormalBlend_Emissive_Base, NormalBlend_Emissive_Detail) / NormalBlend_Emissive_Base.z - NormalBlend_Emissive_Detail;
    float2 _ViewNormalAsEmissiveUV = noSknewViewNormal_Emissive.xy*0.5 + 0.5;
    float2 _ViewCoord_UV = RotateUV(_ViewNormalAsEmissiveUV, -(cameraParam._Camera_Dir*cameraParam._Camera_Roll), float2(0.5, 0.5), 1.0);
    //鏡の中ならUV左右反転.
    if (cameraParam._sign_Mirror < 0) {
        _ViewCoord_UV.x = 1 - _ViewCoord_UV.x;
    }else{
        _ViewCoord_UV = _ViewCoord_UV;
    }
    float2 emissive_uv = lerp(i.uv0, _ViewCoord_UV, _Is_ViewCoord_Scroll);
    //
    float4 _time_var = _Time;
    float _base_Speed_var = (_time_var.g*_Base_Speed);
    float _Is_PingPong_Base_var = lerp(_base_Speed_var, sin(_base_Speed_var), _Is_PingPong_Base);
    float2 scrolledUV = emissive_uv - float2(_Scroll_EmissiveU, _Scroll_EmissiveV)*_Is_PingPong_Base_var;
    float rotateVelocity = _Rotate_EmissiveUV * 3.141592654;
    float2 _rotate_EmissiveUV_var = RotateUV(scrolledUV, rotateVelocity, float2(0.5, 0.5), _Is_PingPong_Base_var);
    float4 _Emissive_Tex_var = tex2D(_Emissive_Tex, TRANSFORM_TEX(Set_UV0, _Emissive_Tex));
    float emissiveMask = _Emissive_Tex_var.a;
    _Emissive_Tex_var = tex2D(_Emissive_Tex, TRANSFORM_TEX(_rotate_EmissiveUV_var, _Emissive_Tex));
    float _colorShift_Speed_var = 1.0 - cos(_time_var.g*_ColorShift_Speed);
    float viewShift_var = smoothstep(0.0, 1.0, max(0, dot(normalDirection, viewDirection)));
    float4 colorShift_Color = lerp(_Emissive_Color, lerp(_Emissive_Color, _ColorShift, _colorShift_Speed_var), _Is_ColorShift);
    float4 viewShift_Color = lerp(_ViewShift, colorShift_Color, viewShift_var);
    float4 emissive_Color = lerp(colorShift_Color, viewShift_Color, _Is_ViewShift);
    emissive = emissive_Color.rgb * _Emissive_Tex_var.rgb * emissiveMask;
#endif
}

float3 compForwardBase(
    VertexOutput i, float3x3 tangentTransform, float3 viewDirection, float3 normalDirection,
    float3 lightColor, float3 lightDirection, float3 halfDirection,
    float4 _MainTex_var, float2 Set_UV0, float attenuation)
{
    float3 Set_LightColor = lightColor.rgb;
    float _HalfLambert_var = 0.5*dot(lerp(i.normalDir, normalDirection, _Is_NormalMapToBase), lightDirection) + 0.5;
    float4 _Set_1st_ShadePosition_var = tex2D(_Set_1st_ShadePosition, TRANSFORM_TEX(Set_UV0, _Set_1st_ShadePosition));
    //v.2.0.6
    //Minmimum value is same as the Minimum Feather's value with the Minimum Step's value as threshold.
    float _SystemShadowsLevel_var = (attenuation*0.5) + 0.5 + _Tweak_SystemShadowsLevel > 0.001 ? (attenuation*0.5) + 0.5 + _Tweak_SystemShadowsLevel : 0.0001;
    float Set_FinalShadowMask = saturate((1.0 + ((lerp(_HalfLambert_var, _HalfLambert_var*saturate(_SystemShadowsLevel_var), _Set_SystemShadowsToBase) - (_BaseColor_Step - _BaseShade_Feather)) * ((1.0 - _Set_1st_ShadePosition_var.rgb).r - 1.0)) / (_BaseColor_Step - (_BaseColor_Step - _BaseShade_Feather))));

    float3 Set_FinalBaseColor = compBaseColor(
        _MainTex_var, Set_UV0,
        Set_LightColor, _HalfLambert_var, _Set_1st_ShadePosition_var,
        _SystemShadowsLevel_var, Set_FinalShadowMask);

    float3 Set_HighColor = compHighColor(i, Set_UV0, normalDirection, halfDirection,
        Set_LightColor, Set_FinalBaseColor, Set_FinalShadowMask);

    float3 Set_RimLight = compRimLight(i, Set_UV0, Set_LightColor, viewDirection, normalDirection, lightDirection);
    //Composition: HighColor and RimLight as _RimLight_var
    float3 _RimLight_var = lerp(Set_HighColor, (Set_HighColor + Set_RimLight), _RimLight);

    CameraParam cameraParam = compCameraParam(i);
    float3 matCapColorFinal = compMatCap(i, tangentTransform, viewDirection, Set_UV0,
        Set_LightColor, Set_FinalShadowMask, Set_HighColor, Set_RimLight, _RimLight_var, cameraParam);
    float3 finalColor = lerp(_RimLight_var, matCapColorFinal, _MatCap);// Final Composition before Emissive

    //v.2.0.6: GI_Intensity with Intensity Multiplier Filter
    float3 envLightColor = DecodeLightProbe(normalDirection) < float3(1, 1, 1) ? DecodeLightProbe(normalDirection) : float3(1, 1, 1);
    float envLightIntensity = 0.299*envLightColor.r + 0.587*envLightColor.g + 0.114*envLightColor.b < 1 ? (0.299*envLightColor.r + 0.587*envLightColor.g + 0.114*envLightColor.b) : 1;

    compEmissive(i, viewDirection, normalDirection, Set_UV0, cameraParam);

    //Final Composition
    float3 envLight = envLightColor * envLightIntensity*_GI_Intensity*smoothstep(1, 0, envLightIntensity / 2);
    finalColor =  saturate(finalColor) + envLight + emissive;

    return finalColor;
}

float3 compForwardDelta(VertexOutput i, float3 normalDirection,
    float3 lightColor, float3 lightDirection, float3 halfDirection,
    float4 _MainTex_var, float2 Set_UV0, float attenuation)
{
    //v.2.0.5:
    _BaseColor_Step = saturate(_BaseColor_Step + _StepOffset);
    _ShadeColor_Step = saturate(_ShadeColor_Step + _StepOffset);
    //
    //v.2.0.5: If Added lights is directional, set 0 as _LightIntensity
    float _LightIntensity = lerp(0, (0.299*_LightColor0.r + 0.587*_LightColor0.g + 0.114*_LightColor0.b)*attenuation, _WorldSpaceLightPos0.w);
    //v.2.0.5: Filtering the high intensity zone of PointLights
    float3 Set_LightColor = lerp(lightColor, lerp(lightColor, min(lightColor, _LightColor0.rgb*attenuation*_BaseColor_Step), _WorldSpaceLightPos0.w), _Is_Filter_HiCutPointLightColor);
    //
    float3 Set_BaseColor = lerp((_BaseColor.rgb*_MainTex_var.rgb*_LightIntensity), ((_BaseColor.rgb*_MainTex_var.rgb)*Set_LightColor), _Is_LightColor_Base);
    //v.2.0.5
    float4 _1st_ShadeMap_var = lerp(tex2D(_1st_ShadeMap, TRANSFORM_TEX(Set_UV0, _1st_ShadeMap)), _MainTex_var, _Use_BaseAs1st);
    float3 Set_1st_ShadeColor = lerp((_1st_ShadeColor.rgb*_1st_ShadeMap_var.rgb*_LightIntensity), ((_1st_ShadeColor.rgb*_1st_ShadeMap_var.rgb)*Set_LightColor), _Is_LightColor_1st_Shade);
    //v.2.0.5
    float4 _2nd_ShadeMap_var = lerp(tex2D(_2nd_ShadeMap, TRANSFORM_TEX(Set_UV0, _2nd_ShadeMap)), _1st_ShadeMap_var, _Use_1stAs2nd);
    float3 Set_2nd_ShadeColor = lerp((_2nd_ShadeColor.rgb*_2nd_ShadeMap_var.rgb*_LightIntensity), ((_2nd_ShadeColor.rgb*_2nd_ShadeMap_var.rgb)*Set_LightColor), _Is_LightColor_2nd_Shade);
    float _HalfLambert_var = 0.5*dot(lerp(i.normalDir, normalDirection, _Is_NormalMapToBase), lightDirection) + 0.5;
    float4 _Set_2nd_ShadePosition_var = tex2D(_Set_2nd_ShadePosition, TRANSFORM_TEX(Set_UV0, _Set_2nd_ShadePosition));
    float4 _Set_1st_ShadePosition_var = tex2D(_Set_1st_ShadePosition, TRANSFORM_TEX(Set_UV0, _Set_1st_ShadePosition));
    //v.2.0.5:
    float Set_FinalShadowMask = saturate((1.0 + ((lerp(_HalfLambert_var, (_HalfLambert_var*saturate(1.0 + _Tweak_SystemShadowsLevel)), _Set_SystemShadowsToBase) - (_BaseColor_Step - _BaseShade_Feather)) * ((1.0 - _Set_1st_ShadePosition_var.rgb).r - 1.0)) / (_BaseColor_Step - (_BaseColor_Step - _BaseShade_Feather))));
    //Composition: 3 Basic Colors as finalColor
    float3 finalColor = lerp(Set_BaseColor, lerp(Set_1st_ShadeColor, Set_2nd_ShadeColor, saturate((1.0 + ((_HalfLambert_var - (_ShadeColor_Step - _1st2nd_Shades_Feather)) * ((1.0 - _Set_2nd_ShadePosition_var.rgb).r - 1.0)) / (_ShadeColor_Step - (_ShadeColor_Step - _1st2nd_Shades_Feather))))), Set_FinalShadowMask); // Final Color

    //v.2.0.6: Add HighColor if _Is_Filter_HiCutPointLightColor is False
    float4 _Set_HighColorMask_var = tex2D(_Set_HighColorMask, TRANSFORM_TEX(Set_UV0, _Set_HighColorMask));
    float _Specular_var = 0.5*dot(halfDirection, lerp(i.normalDir, normalDirection, _Is_NormalMapToHighColor)) + 0.5; //  Specular                
    float _TweakHighColorMask_var = (saturate((_Set_HighColorMask_var.g + _Tweak_HighColorMaskLevel))*lerp((1.0 - step(_Specular_var, (1.0 - pow(_HighColor_Power, 5)))), pow(_Specular_var, exp2(lerp(11, 1, _HighColor_Power))), _Is_SpecularToHighColor));
    float4 _HighColor_Tex_var = tex2D(_HighColor_Tex, TRANSFORM_TEX(Set_UV0, _HighColor_Tex));
    float3 _HighColor_var = (lerp((_HighColor_Tex_var.rgb*_HighColor.rgb), ((_HighColor_Tex_var.rgb*_HighColor.rgb)*Set_LightColor), _Is_LightColor_HighColor)*_TweakHighColorMask_var);
    finalColor = finalColor + lerp(lerp(_HighColor_var, (_HighColor_var*((1.0 - Set_FinalShadowMask) + (Set_FinalShadowMask*_TweakHighColorOnShadow))), _Is_UseTweakHighColorOnShadow), float3(0, 0, 0), _Is_Filter_HiCutPointLightColor);
    //

    finalColor = saturate(finalColor);

    return finalColor;
}

float4 compFinalRGBA(float3 finalColor, float _Inverse_Clipping_var)
{
    //v.2.0.4
    #ifdef _IS_CLIPPING_OFF
    //DoubleShadeWithFeather
        #ifdef _IS_PASS_FWDBASE
            fixed4 finalRGBA = fixed4(finalColor, 1);
        #elif _IS_PASS_FWDDELTA
            fixed4 finalRGBA = fixed4(finalColor, 0);
        #endif
    #elif _IS_CLIPPING_MODE
    //DoubleShadeWithFeather_Clipping
        #ifdef _IS_PASS_FWDBASE
            fixed4 finalRGBA = fixed4(finalColor, 1);
        #elif _IS_PASS_FWDDELTA
            fixed4 finalRGBA = fixed4(finalColor, 0);
        #endif
    #elif _IS_CLIPPING_TRANSMODE
    //DoubleShadeWithFeather_TransClipping
        float Set_Opacity = saturate((_Inverse_Clipping_var + _Tweak_transparency));
        #ifdef _IS_PASS_FWDBASE
            fixed4 finalRGBA = fixed4(finalColor, Set_Opacity);
        #elif _IS_PASS_FWDDELTA
            fixed4 finalRGBA = fixed4(finalColor * Set_Opacity, 0);
        #endif
    #endif

    return finalRGBA;
}

float4 frag(VertexOutput i, fixed facing : VFACE) : SV_TARGET {
    i.normalDir = normalize(i.normalDir);
    float3x3 tangentTransform = float3x3( i.tangentDir, i.bitangentDir, i.normalDir);
    float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
    float2 Set_UV0 = i.uv0;

    float3 normalDirection = compNormalDirection(Set_UV0, tangentTransform);
    float4 _MainTex_var = tex2D(_MainTex,TRANSFORM_TEX(Set_UV0, _MainTex));

    float _Inverse_Clipping_var = clipping(Set_UV0, _MainTex_var);
    UNITY_LIGHT_ATTENUATION(attenuation, i, i.posWorld.xyz);

    float3 lightDirection = compLightDirection(i);
    float3 lightColor = compLightColor(i, lightDirection, normalDirection, attenuation);
////// Lighting:
    float3 halfDirection = normalize(viewDirection+lightDirection);
    //v.2.0.5
    _Color = _BaseColor;

#ifdef _IS_PASS_FWDBASE
    float3 finalColor = compForwardBase(
        i, tangentTransform, viewDirection, normalDirection,
        lightColor, lightDirection, halfDirection,
        _MainTex_var, Set_UV0, attenuation);
#elif _IS_PASS_FWDDELTA
    float3 finalColor = compForwardDelta(
        i, normalDirection,
        lightColor, lightDirection, halfDirection,
        _MainTex_var, Set_UV0, attenuation);
#endif

    float4 finalRGBA = compFinalRGBA(finalColor, _Inverse_Clipping_var);
    UNITY_APPLY_FOG(i.fogCoord, finalRGBA);
    return finalRGBA;
}
