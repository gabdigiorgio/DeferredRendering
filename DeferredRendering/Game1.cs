using DeferredRendering.Cameras;
using DeferredRendering.Geometries.Textures;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;

namespace DeferredRendering
{
    public class Game1 : Game
    {
        public const string ContentFolder3D = "Models/";
        public const string ContentFolderEffects = "Effects/";
        public const string ContentFolderTextures = "Textures/";

        private GraphicsDeviceManager _graphicsDeviceManager;
        private SpriteBatch _spriteBatch;
        
        // Camera
        private FreeCamera _freeCamera;
        private readonly Vector3 _cameraInitialPosition = new(0f, 50f, 100f);
        
        // Scene
        private Vector3 _lightPosition = new(250f, 100f, 0f);
        private Effect _blinnPhongShader;
        private Texture2D _brickTexture;
        
        private Model _sphereModel;
        private Matrix _sphereWorld;
        private readonly Vector3 _spherePosition = new(0f, 25f, -100f);
        private readonly Vector3 _sphereScale = new(25f, 25f, 25f);

        private QuadPrimitive _quad;
        private Matrix _quadWorld;
        private readonly Vector3 _quadPosition = new(0f, 0f, -100f);
        private readonly Vector3 _quadScale = new(500f, 0f, 500f);

        public Game1()
        {
            _graphicsDeviceManager = new GraphicsDeviceManager(this);
            Content.RootDirectory = "Content";
            IsMouseVisible = true;
            Window.AllowUserResizing = true;
        }

        protected override void Initialize()
        {
            _graphicsDeviceManager.PreferredBackBufferWidth = GraphicsAdapter.DefaultAdapter.CurrentDisplayMode.Width - 100;
            _graphicsDeviceManager.PreferredBackBufferHeight = GraphicsAdapter.DefaultAdapter.CurrentDisplayMode.Height - 100;
            _graphicsDeviceManager.ApplyChanges();
            
            _freeCamera = new FreeCamera(GraphicsDevice.Viewport.AspectRatio, _cameraInitialPosition);
            
            _sphereWorld = Matrix.CreateScale(_sphereScale) * Matrix.CreateTranslation(_spherePosition);
            
            _quadWorld = Matrix.CreateScale(_quadScale) * Matrix.CreateTranslation(_quadPosition);
            _quad = new QuadPrimitive(GraphicsDevice);

            base.Initialize();
        }

        protected override void LoadContent()
        {
            _spriteBatch = new SpriteBatch(GraphicsDevice);
            _blinnPhongShader = Content.Load<Effect>(ContentFolderEffects + "BlinnPhong");
            _sphereModel = Content.Load<Model>(ContentFolder3D + "sphere");
            _brickTexture = Content.Load<Texture2D>(ContentFolderTextures + "brick");
            LoadEffectOnMesh(_sphereModel, _blinnPhongShader);
            
            base.LoadContent();
        }
        
        private static void LoadEffectOnMesh(Model model, Effect effect)
        {
            foreach (var mesh in model.Meshes)
            {
                foreach (var meshPart in mesh.MeshParts)
                {
                    meshPart.Effect = effect;
                }
            }
        }

        protected override void Update(GameTime gameTime)
        {
            var keyboardState = Keyboard.GetState();

            if (keyboardState.IsKeyDown(Keys.Escape))
            {
                Exit();
            }
            
            _freeCamera.Update(gameTime);

            base.Update(gameTime);
        }

        protected override void Draw(GameTime gameTime)
        {
            GraphicsDevice.Clear(Color.CornflowerBlue);

            DrawQuad();
            DrawSphere();

            base.Draw(gameTime);
        }

        private void DrawQuad()
        {
            _blinnPhongShader.CurrentTechnique = _blinnPhongShader.Techniques["BasicTextureDrawing"];
            _blinnPhongShader.Parameters["BaseTexture"].SetValue(_brickTexture);
            _blinnPhongShader.Parameters["Tiling"].SetValue(Vector2.One * 10f); 
            
            _blinnPhongShader.Parameters["World"].SetValue(_quadWorld);
            _blinnPhongShader.Parameters["View"].SetValue(_freeCamera.View);
            _blinnPhongShader.Parameters["Projection"].SetValue(_freeCamera.Projection);
            _blinnPhongShader.Parameters["InverseTransposeWorld"].SetValue(Matrix.Invert(Matrix.Transpose(_quadWorld)));
            
            _blinnPhongShader.Parameters["AmbientColor"].SetValue(Color.White.ToVector3());
            _blinnPhongShader.Parameters["KAmbient"].SetValue(0.3f);
            
            _blinnPhongShader.Parameters["LightPosition"].SetValue(_lightPosition);
            
            _blinnPhongShader.Parameters["DiffuseColor"].SetValue(Color.White.ToVector3());
            _blinnPhongShader.Parameters["KDiffuse"].SetValue(0.7f);
            
            _blinnPhongShader.Parameters["EyePosition"].SetValue(_freeCamera.Position);
            
            _blinnPhongShader.Parameters["SpecularColor"].SetValue(Color.White.ToVector3());
            _blinnPhongShader.Parameters["KSpecular"].SetValue(0.4f);
            _blinnPhongShader.Parameters["Shininess"].SetValue(32f);
            
            _quad.Draw(_blinnPhongShader);
        }

        private void DrawSphere()
        {
            _blinnPhongShader.CurrentTechnique = _blinnPhongShader.Techniques["BasicColorDrawing"];
            _blinnPhongShader.Parameters["Color"].SetValue(Color.Green.ToVector3());
            
            _blinnPhongShader.Parameters["World"].SetValue(_sphereWorld);
            _blinnPhongShader.Parameters["View"].SetValue(_freeCamera.View);
            _blinnPhongShader.Parameters["Projection"].SetValue(_freeCamera.Projection);
            _blinnPhongShader.Parameters["InverseTransposeWorld"].SetValue(Matrix.Invert(Matrix.Transpose(_sphereWorld)));
            
            _blinnPhongShader.Parameters["AmbientColor"].SetValue(Color.White.ToVector3());
            _blinnPhongShader.Parameters["KAmbient"].SetValue(0.3f);
            
            _blinnPhongShader.Parameters["LightPosition"].SetValue(_lightPosition);
            
            _blinnPhongShader.Parameters["DiffuseColor"].SetValue(Color.White.ToVector3());
            _blinnPhongShader.Parameters["KDiffuse"].SetValue(0.7f);
            
            _blinnPhongShader.Parameters["EyePosition"].SetValue(_freeCamera.Position);
            
            _blinnPhongShader.Parameters["SpecularColor"].SetValue(Color.White.ToVector3());
            _blinnPhongShader.Parameters["KSpecular"].SetValue(1f);
            _blinnPhongShader.Parameters["Shininess"].SetValue(32f);
            
            foreach (var mesh in _sphereModel.Meshes)
            {
                mesh.Draw();
            }
        }
    }
}