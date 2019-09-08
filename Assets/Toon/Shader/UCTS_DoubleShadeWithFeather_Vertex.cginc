struct VertexInput {
	float4 vertex : POSITION;
	float3 normal : NORMAL;
	float4 tangent : TANGENT;
	float2 texcoord0 : TEXCOORD0;
};

VertexOutput vert (VertexInput v) {
    VertexOutput o = (VertexOutput)0;
    o.uv0 = v.texcoord0;
    o.normalDir = UnityObjectToWorldNormal(v.normal);
    o.tangentDir = normalize( mul( unity_ObjectToWorld, float4( v.tangent.xyz, 0.0 ) ).xyz );
    o.bitangentDir = normalize(cross(o.normalDir, o.tangentDir) * v.tangent.w);
    o.posWorld = mul(unity_ObjectToWorld, v.vertex);
    float3 lightColor = _LightColor0.rgb;
    o.pos = UnityObjectToClipPos( v.vertex );
    //v.2.0.7 鏡の中判定（右手座標系か、左手座標系かの判定）o.mirrorFlag = -1 なら鏡の中.
    float3 crossFwd = cross(UNITY_MATRIX_V[0], UNITY_MATRIX_V[1]);
    o.mirrorFlag = dot(crossFwd, UNITY_MATRIX_V[2]) < 0 ? 1 : -1;
    //
    UNITY_TRANSFER_FOG(o,o.pos);
    TRANSFER_VERTEX_TO_FRAGMENT(o)
    return o;
}