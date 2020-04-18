namespace Engine
{
    public class OpenGLStandardShaderBuilder : OpenGLShaderBuilder
    {
        public OpenGLStandardShaderBuilder(MaterialSpecification spec, int max_lights = 2)
        {
            OpenGLShaderDefine max_lights_define = new OpenGLShaderDefine("MAX_LIGHTS", max_lights.to_string());

            OpenGLShaderDefine blend_color_define = new OpenGLShaderDefine("BLEND_COLOR", "1");
            OpenGLShaderDefine blend_texture_define = new OpenGLShaderDefine("BLEND_TEXTURE", "2");
            OpenGLShaderDefine blend_with_material_multiplier_define = new OpenGLShaderDefine("BLEND_WITH_MATERIAL_MULTIPLIER", "3");
            OpenGLShaderDefine blend_without_material_multiplier_define = new OpenGLShaderDefine("BLEND_WITHOUT_MATERIAL_MULTIPLIER", "4");
            OpenGLShaderDefine blend_label_define = new OpenGLShaderDefine("BLEND_LABEL", "5");

            OpenGLShaderUniform projection_transform_uniform = new OpenGLShaderUniform("projection_transform", OpenGLShaderPrimitiveType.MAT4);
            OpenGLShaderUniform camera_position_uniform = new OpenGLShaderUniform("camera_position", OpenGLShaderPrimitiveType.VEC3);
            //OpenGLShaderUniform view_transform_uniform = new OpenGLShaderUniform("view_transform", OpenGLShaderPrimitiveType.MAT4);
            OpenGLShaderUniform model_transform_uniform = new OpenGLShaderUniform("model_transform", OpenGLShaderPrimitiveType.MAT4);
            //OpenGLShaderUniform un_projection_transform_uniform = new OpenGLShaderUniform("un_projection_transform", OpenGLShaderPrimitiveType.MAT4);
            //OpenGLShaderUniform un_view_transform_uniform = new OpenGLShaderUniform("un_view_transform", OpenGLShaderPrimitiveType.MAT4);
            //OpenGLShaderUniform un_model_transform_uniform = new OpenGLShaderUniform("un_model_transform", OpenGLShaderPrimitiveType.MAT4);

            OpenGLShaderStruct light_source_struct = new OpenGLShaderStruct("lightSourceParameters",
            {
                new OpenGLShaderProperty("position", OpenGLShaderPrimitiveType.VEC3),
                new OpenGLShaderProperty("color", OpenGLShaderPrimitiveType.VEC3),
                new OpenGLShaderProperty("intensity", OpenGLShaderPrimitiveType.FLOAT)
            });
            

            OpenGLShaderUniform light_count_float_uniform = new OpenGLShaderUniform("light_count_float", OpenGLShaderPrimitiveType.FLOAT);
            OpenGLShaderUniform light_count_uniform = new OpenGLShaderUniform("light_count", OpenGLShaderPrimitiveType.INT);
            OpenGLShaderUniform light_source_uniform = new OpenGLShaderUniform("light_source", OpenGLShaderPrimitiveType.CUSTOM)
            {
                array = max_lights_define.name,
                custom_type = light_source_struct.name,
                dependencies = { light_source_struct, max_lights_define }
            };

            OpenGLShaderUniform alpha_uniform = new OpenGLShaderUniform("alpha", OpenGLShaderPrimitiveType.FLOAT);
            OpenGLShaderUniform target_color_uniform = new OpenGLShaderUniform("target_color", OpenGLShaderPrimitiveType.VEC4);
            OpenGLShaderUniform target_color_strength_uniform = new OpenGLShaderUniform("target_color_strength", OpenGLShaderPrimitiveType.FLOAT);
            OpenGLShaderDefine specular_exponent_define = new OpenGLShaderDefine("specular_exponent", spec.specular_exponent.to_string("%.6f"));
            OpenGLShaderUniform textures_uniform = new OpenGLShaderUniform("textures", OpenGLShaderPrimitiveType.SAMPLER2D)
            { array = spec.textures.to_string() };

            //OpenGLShaderUniform ambient_material_multiplier_uniform = new OpenGLShaderUniform("ambient_material_multiplier", OpenGLShaderPrimitiveType.FLOAT);
            OpenGLShaderUniform ambient_color_uniform = new OpenGLShaderUniform("ambient_color", OpenGLShaderPrimitiveType.VEC4);
            //OpenGLShaderUniform diffuse_material_multiplier_uniform = new OpenGLShaderUniform("diffuse_material_multiplier", OpenGLShaderPrimitiveType.FLOAT);
            OpenGLShaderUniform diffuse_color_uniform = new OpenGLShaderUniform("diffuse_color", OpenGLShaderPrimitiveType.VEC4);
            //OpenGLShaderUniform specular_material_multiplier_uniform = new OpenGLShaderUniform("specular_material_multiplier", OpenGLShaderPrimitiveType.FLOAT);
            OpenGLShaderUniform specular_color_uniform = new OpenGLShaderUniform("specular_color", OpenGLShaderPrimitiveType.VEC4);
            
            OpenGLShaderVarying frag_normal_varying = new OpenGLShaderVarying("frag_normal", OpenGLShaderPrimitiveType.VEC3);
            OpenGLShaderVarying frag_camera_normal_varying = new OpenGLShaderVarying("frag_camera_normal", OpenGLShaderPrimitiveType.VEC3);

            OpenGLShaderVarying diffuse_strength_varying = new OpenGLShaderVarying("diffuse_strength", OpenGLShaderPrimitiveType.VEC4);
            OpenGLShaderVarying specular_strength_varying = new OpenGLShaderVarying("specular_strength", OpenGLShaderPrimitiveType.VEC4);

            OpenGLShaderVarying light_normals_varying = new OpenGLShaderVarying("light_normals", OpenGLShaderPrimitiveType.VEC3)
            { array = max_lights_define.name, dependencies = { max_lights_define } };
            OpenGLShaderVarying light_intensity_varying = new OpenGLShaderVarying("light_intensity", OpenGLShaderPrimitiveType.FLOAT)
            { array = max_lights_define.name, dependencies = { max_lights_define } };
            OpenGLShaderVarying light_colors_varying = new OpenGLShaderVarying("light_colors", OpenGLShaderPrimitiveType.VEC3)
            { array = max_lights_define.name, dependencies = { max_lights_define } };
            
            OpenGLShaderVarying frag_texture_coord_varying = new OpenGLShaderVarying("frag_texture_coord", OpenGLShaderPrimitiveType.VEC2);
            
            OpenGLShaderAttribute position_attribute = new OpenGLShaderAttribute("position", OpenGLShaderPrimitiveType.VEC4);
            OpenGLShaderAttribute texture_coord_attribute = new OpenGLShaderAttribute("texture_coord", OpenGLShaderPrimitiveType.VEC3);
            OpenGLShaderAttribute normal_attribute = new OpenGLShaderAttribute("normal", OpenGLShaderPrimitiveType.VEC3);

            OpenGLShaderCodeBlock calculate_lighting_factor_code = new OpenGLShaderCodeBlock(calculate_lighting_factor_code_string)
            {
                dependencies = { frag_normal_varying, frag_camera_normal_varying, light_intensity_varying, light_normals_varying, light_colors_varying,
                specular_exponent_define, light_count_uniform, light_count_float_uniform }
            };

            OpenGLShaderFunction calculate_lighting_factor_function = new OpenGLShaderFunction("calculate_lighting_factor", OpenGLShaderPrimitiveType.VOID);
            calculate_lighting_factor_function.parameters =
            {
                new OpenGLShaderProperty("diffuse_out", OpenGLShaderPrimitiveType.VEC4) { direction = OpenGLShaderPropertyDirection.OUT },
                new OpenGLShaderProperty("specular_out", OpenGLShaderPrimitiveType.VEC4) { direction = OpenGLShaderPropertyDirection.OUT },
            };
            calculate_lighting_factor_function.add_code(calculate_lighting_factor_code);

            OpenGLShaderCodeBlock base_color_blend_code = new OpenGLShaderCodeBlock(base_color_blend_code_string)
            {
                dependencies = { blend_color_define, blend_texture_define,
                    blend_with_material_multiplier_define, blend_without_material_multiplier_define, blend_label_define }
            };

            OpenGLShaderFunction base_color_blend_function = new OpenGLShaderFunction("base_color_blend", OpenGLShaderPrimitiveType.VEC4)
            {
                parameters =
                {
                    new OpenGLShaderProperty("color", OpenGLShaderPrimitiveType.VEC4),
                    new OpenGLShaderProperty("texture_color", OpenGLShaderPrimitiveType.VEC4),
                    new OpenGLShaderProperty("material_multiplier", OpenGLShaderPrimitiveType.FLOAT),
                    new OpenGLShaderProperty("type", OpenGLShaderPrimitiveType.INT)
                }
            };
            base_color_blend_function.add_code(base_color_blend_code);

            OpenGLShaderCodeBlock vertex_mod_pos_code = new OpenGLShaderCodeBlock(vertex_mod_pos_code_string)
            { dependencies = { model_transform_uniform, position_attribute } };

            OpenGLShaderCodeBlock vertex_light_code = new OpenGLShaderCodeBlock(vertex_light_code_string)
            {
                dependencies = { vertex_mod_pos_code,
                light_normals_varying, light_intensity_varying, light_colors_varying,
                light_count_uniform, light_source_uniform }
            };

            OpenGLShaderCodeBlock vertex_start_code = new OpenGLShaderCodeBlock(vertex_start_code_string)
            {
                dependencies = { vertex_mod_pos_code, position_attribute, texture_coord_attribute, normal_attribute,
                frag_texture_coord_varying, frag_normal_varying, frag_camera_normal_varying,
                projection_transform_uniform, camera_position_uniform, model_transform_uniform }
            };

            OpenGLShaderCodeBlock fragment_alpha_discard_code = new OpenGLShaderCodeBlock(fragment_alpha_discard_code_string)
            { dependencies = { alpha_uniform } };

            /*OpenGLShaderCodeBlock fragment_start_code = new OpenGLShaderCodeBlock(fragment_start_code_string)
            {
                dependencies = { frag_texture_coord_varying,
                textures_uniform, ambient_material_multiplier_uniform, ambient_color_uniform,
                diffuse_material_multiplier_uniform, diffuse_color_uniform, specular_material_multiplier_uniform, specular_color_uniform,
                base_color_blend_function }
            };*/

            OpenGLShaderCodeBlock define_local_vars_code = new OpenGLShaderCodeBlock(define_local_vars_code_string);

            OpenGLShaderCodeBlock do_calculate_lighting_code = new OpenGLShaderCodeBlock(do_calculate_lighting_code_string)
            { dependencies = { calculate_lighting_factor_function } };

            OpenGLShaderCodeBlock fragment_single_texture_code = new OpenGLShaderCodeBlock(fragment_single_texture_code_string)
            { dependencies = { textures_uniform, frag_texture_coord_varying } };


            if (spec.alpha != UniformType.NONE)
                add_fragment_block(fragment_alpha_discard_code);

            if (spec.lighting_calculation != LightingCalculationType.NONE)
                add_vertex_block(vertex_light_code);

            if (spec.lighting_calculation == LightingCalculationType.FRAGMENT)
                do_calculate_lighting_code.add_dependency(define_local_vars_code);
            else if (spec.lighting_calculation == LightingCalculationType.VERTEX)
            {
                do_calculate_lighting_code.add_dependency(diffuse_strength_varying);
                do_calculate_lighting_code.add_dependency(specular_strength_varying);
                fragment_main.add_dependency(diffuse_strength_varying);
                fragment_main.add_dependency(specular_strength_varying);
            }

            add_vertex_block(vertex_start_code);
            if (spec.lighting_calculation == LightingCalculationType.VERTEX)
                add_vertex_block(do_calculate_lighting_code);
            //if (spec.lighting_calculation != LightingCalculationType.NONE)
            //    add_vertex_block(fragment_color_multiply_code);

            if (spec.lighting_calculation == LightingCalculationType.FRAGMENT)
                add_fragment_block(do_calculate_lighting_code);

            
            string? texture = null;
            if (spec.textures != 0)
                texture = "texture";

            if (spec.textures == 1)
                add_fragment_block(fragment_single_texture_code);
            
            if (spec.texture_map)
                add_fragment_block(new OpenGLShaderCodeBlock("if (texture.a <= 0.0) discard;"));

            add_fragment_block(new OpenGLShaderCodeBlock("vec4 ambient = "));

            string? ambient = null;
            if (spec.ambient_color == UniformType.STATIC)
                ambient = color_to_string(spec.static_ambient_color);
            else if (spec.ambient_color == UniformType.DYNAMIC)
            {
                fragment_main.add_dependency(ambient_color_uniform);
                ambient = ambient_color_uniform.name;
            }

            ambient = blend(spec.ambient_blend_type, texture, ambient);
            if (spec.ambient_strength == 0)
                ambient = "vec4(0.0)";
            else if (spec.ambient_strength != 1)
                ambient += " * " + spec.ambient_strength.to_string();
            add_fragment_block(new OpenGLShaderCodeBlock(ambient + ";"));

            if (spec.lighting_calculation != LightingCalculationType.NONE)
            {
                add_fragment_block(new OpenGLShaderCodeBlock("vec4 diffuse = "));
                string? diffuse = null;
                if (spec.diffuse_color == UniformType.STATIC)
                    diffuse = color_to_string(spec.static_diffuse_color);
                else if (spec.diffuse_color == UniformType.DYNAMIC)
                {
                    fragment_main.add_dependency(diffuse_color_uniform);
                    diffuse = diffuse_color_uniform.name;
                }
                diffuse = blend(spec.diffuse_blend_type, texture, diffuse);
                if (spec.diffuse_strength == 0)
                    diffuse = "vec4(0.0)";
                else if (spec.diffuse_strength != 1)
                    diffuse += " * " + spec.diffuse_strength.to_string();
                add_fragment_block(new OpenGLShaderCodeBlock(diffuse + ";"));

                add_fragment_block(new OpenGLShaderCodeBlock("vec4 specular = "));
                string? specular = null;
                if (spec.specular_color == UniformType.STATIC)
                    specular = color_to_string(spec.static_specular_color);
                else if (spec.specular_color == UniformType.DYNAMIC)
                {
                    fragment_main.add_dependency(specular_color_uniform);
                    specular = specular_color_uniform.name;
                }
                specular = blend(spec.specular_blend_type, texture, specular);
                if (spec.specular_strength == 0)
                    specular = "vec4(0.0)";
                else if (spec.specular_strength != 1)
                    specular += " * " + spec.specular_strength.to_string();
                add_fragment_block(new OpenGLShaderCodeBlock(specular + ";"));


                add_fragment_block(new OpenGLShaderCodeBlock("vec4 color = " + lighting_blend(ambient, diffuse, specular) + ";"));
            }
            else
                add_fragment_block(new OpenGLShaderCodeBlock("vec4 color = ambient;"));

            string alpha = "1.0";
            if (spec.alpha == UniformType.STATIC)
                alpha = spec.static_alpha.to_string();
            else if (spec.alpha == UniformType.DYNAMIC)
            {
                alpha = alpha_uniform.name;
                fragment_main.add_dependency(alpha_uniform);
            }

            if (spec.target_color != UniformType.NONE)
            {
                string target;
                if (spec.target_color == UniformType.STATIC)
                    target = color_to_string(spec.static_target_color);
                else
                {
                    target = target_color_uniform.name;
                    fragment_main.add_dependency(target_color_uniform);
                }

                fragment_main.add_dependency(target_color_strength_uniform);
                add_fragment_block(new OpenGLShaderCodeBlock("color = color * (1.0 - " + target_color_strength_uniform.name + ") + " + target + " * " + target_color_strength_uniform.name + ";"));
            }
        
            add_fragment_block(new OpenGLShaderCodeBlock("gl_FragColor = vec4(color.xyz, " + alpha + ");"));
        }

        private static string blend(TextureBlendType blend, string? texture, string? color)
        {
            if (blend == TextureBlendType.ALPHA)
                return texture_alpha_blend(texture, color);
            else if (blend == TextureBlendType.MAP)
                return texture_map_blend(texture, color);
            else if (blend == TextureBlendType.COLOR)
            {
                if (color != null) return color;
            }
            else if (blend == TextureBlendType.TEXTURE)
            {
                if (texture != null) return texture;
            }

            return "vec4(0.0)";
        }

        /*private static string float_blend(string? texture, string? color, float texture_strength)
        {
            if (texture == null && color == null)
                return "vec4(0.0)";
            
            if (texture == null || texture_strength <= 0.0)
                return "(" + color + ") * " + (1.0 - texture_strength).to_string();
            else if (color == null  || texture_strength >= 1.0)
                return "(" + texture + ") * " + texture_strength.to_string();

            return 
                "((" + color + ") * " + (1.0 - texture_strength).to_string() + " + " +
                "(" + texture + ") * " + texture_strength.to_string() + ")";
        }*/

        private static string texture_alpha_blend(string? texture, string? color)
        {
            if (texture == null && color == null)
                return "vec4(0.0)";
            
            if (texture == null)
                return "(" + color + ")";
            else if (color == null)
                return "(" + texture + ")";

            return 
                "((" + color + ") * (1.0 - (" + texture + ").a) + " +
                "(" + texture + "))";
        }

        private static string texture_map_blend(string? texture, string? color)
        {
            if (texture == null || color == null)
                return "vec4(0.0)";

            return "((" + color + ") * (" + texture + ").a)";
        }

        private static string color_to_string(Color color)
        {
            string format = "%.6f";
            return "vec4(" +
                color.r.to_string(format) + ", " +
                color.g.to_string(format) + ", " +
                color.b.to_string(format) + ", " +
                color.a.to_string(format) + ")";
        }

        private string lighting_blend(string ambient, string diffuse, string specular)
        {
            return ambient + " + " + diffuse + " * diffuse_strength + " + specular + " * specular_strength";
        }

        private string calculate_lighting_factor_code_string = """
            vec4 diffuse_in = vec4(1.0);
            vec4 specular_in = vec4(1.0);
            
            float blend_factor = 0.0;//0.005;
            float constant_factor = 0.01;
            float linear_factor = 0.8;
            float quadratic_factor = 0.5;
                
            vec3 normal = normalize(frag_normal);
            
            vec3 diffuse = vec3(0.0);//diffuse_in;//out_color.xyz * 0.02;
            vec3 specular = vec3(0.0);
            vec3 c = diffuse_in.xyz;//out_color.xyz;
            vec3 cm = normalize(frag_camera_normal);
            
            for (int i = 0; i < MAX_LIGHTS; i++)
            {
                if (float(i) < light_count_float)
                {
                    float intensity = light_intensity[i];
                    float lnlen = max(length(light_normals[i]), 1.0);
                    vec3 ln = normalize(light_normals[i]);
                    
                    float d = max(dot(ln, normal), 0.0);
                    float plus = 0.0;
                    plus += d * constant_factor;
                    plus += d / lnlen * linear_factor;
                    plus += d / pow(lnlen, 2.0) * quadratic_factor;
                    
                    diffuse += (c * (1.0-blend_factor) + light_colors[i] * blend_factor) * plus * intensity;
                    
                    if (dot(ln, normal) > 0.0) // Only reflect on the correct side
                    {
                        float s = max(dot(cm, reflect(-ln, normal)), 0.0);
                        float spec = pow(s, specular_exponent);
                        
                        float p = 0.0;
                        p += spec * constant_factor;
                        p += spec / lnlen * linear_factor;
                        p += spec / pow(lnlen, 2.0) * quadratic_factor;
                        
                        p = max(p, 0.0) * intensity;
                        
                        specular += (light_colors[i] * (1.0-blend_factor) * 0.0 + specular_in.xyz) * p;
                    }
                }
            }
            
            /*float dist = max(pow(length(frag_camera_normal) / 5.0, 1.0) / 10.0, 1.0);
            diffuse /= dist;
            specular /= dist;*/
            
            diffuse_out = vec4(diffuse, 1.0);
            specular_out = vec4(specular, 1.0);
        """;


        private string base_color_blend_code_string = """
            if (type == BLEND_COLOR)
                return color;
            else if (type == BLEND_TEXTURE)
                return texture_color;
            else if (type == BLEND_WITH_MATERIAL_MULTIPLIER)
                return color * color.a * (1.0 - texture_color.a * material_multiplier) + texture_color * texture_color.a * material_multiplier;
            else if (type == BLEND_WITHOUT_MATERIAL_MULTIPLIER)
                return color * color.a * (1.0 - texture_color.a)                       + texture_color * texture_color.a * material_multiplier;
            else
                return vec4(0.0);
        """;

        private string vertex_mod_pos_code_string = """
            vec3 mod_pos = (model_transform * position).xyz;
        """;

        private string vertex_light_code_string = """
            for (int i = 0; i < light_count; i++)
            {
                light_normals[i] = light_source[i].position - mod_pos;
                light_intensity[i] = light_source[i].intensity;
                light_colors[i] = light_source[i].color;
            }
        """;
        
        private string vertex_start_code_string = """
            frag_texture_coord = texture_coord.xy;
            frag_normal = (model_transform * vec4(normalize(normal), 1.0)).xyz - (model_transform * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
            frag_camera_normal = camera_position - mod_pos;
            gl_Position = projection_transform * model_transform * position;
        """;

        private string do_calculate_lighting_code_string = """
            vec4 diffuse_str, specular_str;
            calculate_lighting_factor(diffuse_str, specular_str);
            diffuse_strength = diffuse_str;
            specular_strength = specular_str;
        """;

        private string fragment_alpha_discard_code_string = """
            if (alpha <= 0.0) discard;
        """;

        private string fragment_single_texture_code_string = """
            vec4 texture = texture2D(textures[0], frag_texture_coord);
        """;

        /*private string fragment_color_discard_code_string = """
            if (color.a <= 0.0) discard;
        """;*/

        private string define_local_vars_code_string = """
            vec4 diffuse_strength;
            vec4 specular_strength;
        """;
    }
}