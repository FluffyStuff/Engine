namespace Engine
{
	public class Transform
	{
		protected Mat4? _matrix;
		protected Vec3 _position;
		protected Vec3 _scale;
		protected Quat _rotation;

		protected Transform? _parent;
		protected Mat4? _parent_matrix;
		protected Mat4? _full_matrix;

		public Transform()
		{
			_matrix = Mat4.get_new();
			_scale = Vec3(1, 1, 1);
			_rotation = Quat();
		}

		public Transform.with_mat(Mat4 mat)
		{
			_matrix = mat;
			dirty_position = true;
			dirty_scale = true;
			dirty_rotation = true;
		}

		private Transform.copy_init() {}

		public Transform copy_shallow_parentless()
		{
			Transform t = new Transform.copy_init();

			t._matrix = _matrix;
			t._position = _position;
			t._scale = _scale;
			t._rotation = _rotation;
			t.dirty_matrix = dirty_matrix;
			t.dirty_position = dirty_position;
			t.dirty_scale = dirty_scale;
			t.dirty_rotation = dirty_rotation;

			return t;
		}

		public Transform copy_full_parentless()
		{
			Transform t = new Transform.copy_init();

			t._matrix = get_full_matrix();
			t.dirty_position = true;
			t.dirty_scale = true;
			t.dirty_rotation = true;

			return t;
		}

		public void change_parent(Transform? parent)
		{
			if (_parent == parent)
				return;
				
			_parent = parent;
			_parent_matrix = null;
			_full_matrix = null;
		}

		public void convert_to_parent(Transform? parent)
		{
			if (_parent == parent)
				return;
			if (_parent != null)
				apply_transform(_parent);

			_parent = parent;
			_parent_matrix = null;
			_full_matrix = null;

			if (parent != null)
			{
				_parent_matrix = parent.get_full_matrix();
				unapply_matrix(_parent_matrix);
			}
		}

		public void apply_transform(Transform t)
		{
			apply_matrix(t.get_full_matrix());
		}

		public void apply_matrix(Mat4 mat)
		{
			matrix = mat.mul_mat(matrix);
		}

		public void unapply_transform(Transform t)
		{
			unapply_matrix(t.get_full_matrix());
		}

		public void unapply_matrix(Mat4 mat)
		{
			matrix = mat.inverse().mul_mat(matrix);
		}

		protected virtual Mat4 calculate_matrix()
		{
			return Calculations.get_model_matrix(_position, _scale, _rotation);
		}

		public Mat4 get_full_matrix()
		{
			if (_parent == null)
				return matrix;
			
			Mat4 m = _parent.get_full_matrix();
			
			if (_full_matrix == null || _parent_matrix == null || dirty_matrix || !m.equals(_parent_matrix))
			{
				_parent_matrix = m;
				_full_matrix = m.mul_mat(matrix);
			}

			return _full_matrix;
		}

		public Mat4 matrix
		{
			get
			{
				if (dirty_matrix)
				{
					_matrix = calculate_matrix();
					_full_matrix = null;
					dirty_matrix = false;
				}

				return _matrix;
			}

			set
			{
				if (!dirty_matrix && _matrix.equals(value))
					return;

				dirty_matrix = false;
				dirty_position = true;
				dirty_scale = true;
				dirty_rotation = true;

				_matrix = value;
				_full_matrix = null;
			}
		}

		public Vec3 position
		{
			get
			{
				if (dirty_position)
				{
					_position = _matrix.get_position();
					dirty_position = false;
				}

				return _position;
			}

			set
			{
				if (!dirty_position && _position == value)
					return;
				
				// Undirty
				_scale = scale;
				_rotation = rotation;
				
				dirty_matrix = true;
				dirty_position = false;

				_position = value;
			}
		}

		public Vec3 scale
		{
			get
			{
				if (dirty_scale)
				{
					_scale = _matrix.get_scale();
					dirty_scale = false;
				}

				return _scale;
			}

			set
			{
				if (!dirty_scale && _scale == value)
					return;
				
				// Undirty
				_position = position;
				_rotation = rotation;
					
				dirty_matrix = true;
				dirty_scale = false;

				_scale = value;
			}
		}

		public Quat rotation
		{
			get
			{
				if (dirty_rotation)
				{
					_rotation = _matrix.get_rotation();
					dirty_rotation = false;
				}

				return _rotation;
			}

			set
			{
				if (!dirty_rotation && _rotation.equals(value))
					return;
				
				// Undirty
				_position = position;
				_scale = scale;
					
				dirty_matrix = true;
				dirty_rotation = false;

				_rotation = value;
			}
		}

		public bool dirty_matrix { get; private set; }
		public bool dirty_position { get; private set; }
		public bool dirty_scale { get; private set; }
		public bool dirty_rotation { get; private set; }
	}

	public class CameraTransform : Transform
	{
		protected override Mat4 calculate_matrix()
		{
			return Calculations.translation_matrix(_position).mul_mat(Calculations.rotation_matrix_quat(_rotation));
		}
	}
}