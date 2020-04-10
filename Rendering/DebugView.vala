using Gee;

namespace Engine
{
    public class DebugView : View2D
    {
        private ArrayList<LabelControl> labels = new ArrayList<LabelControl>();

        protected override void process(DeltaArgs args)
        {
            if (info == null)
            {
                visible = false;
                return;
            }
            else
                visible = true;

            int l = info.strings.size - labels.size;
            for (int i = 0; i < l; i++)
            {
                LabelControl label = new LabelControl();
                add_child(label);
                labels.add(label);
                label.inner_anchor = Vec2(0, 1);
                label.outer_anchor = Vec2(0, 1);
                label.color = Color(0.8f, 0.8f, 0.8f, 1);
                label.font_size = 20;
            }
            
            float p = 0;
            for (int i = 0; i < labels.size; i++)
            {
                LabelControl label = labels[i];
                if (i < info.strings.size)
                {
                    label.text = info.strings[i];
                    label.visible = true;
                    label.position = Vec2(0, -p);

                    p += label.size.height;
                }
                else
                    label.visible = false;
            }
        }

        public DebugInfo? info { get; set; }
    }
}