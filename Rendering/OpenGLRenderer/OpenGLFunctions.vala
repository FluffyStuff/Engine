namespace Engine
{
	class OpenGLFunctions
	{
		private OpenGLFunctions() {}

		public static void glGenVertexArrays(int amount, uint[] vao)
		{
		#if DARWIN
			GL.glGenVertexArraysAPPLE(amount, vao);
		#else
			GL.glGenVertexArrays(amount, vao);
		#endif
		}

		public static void glBindVertexArray(uint array_handle)
		{
		#if DARWIN
			GL.glBindVertexArrayAPPLE(array_handle);
		#else
			GL.glBindVertexArray(array_handle);
		#endif
		}

		public static void glDeleteVertexArrays(int amount, uint[] vao)
		{
		#if DARWIN
			GL.glDeleteVertexArraysAPPLE(amount, vao);
		#else
			GL.glDeleteVertexArrays(amount, vao);
		#endif
		}
	}
}