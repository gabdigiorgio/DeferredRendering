using System;
using DeferredRendering.Cameras;
using DeferredRendering.Geometries;
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
        private Model _sphereModel;
        private Matrix _sphereWorld;
        private readonly Vector3 _spherePosition = new(0f, 25f, -100f);
        private readonly Vector3 _sphereScale = new(25f, 25f, 25f);

        private QuadPrimitive _quad;
        private Matrix _quadWorld;
        private readonly Vector3 _quadPosition = new(0f, 0f, -100f);
        private readonly Vector3 _quadScale = new(500f, 0f, 500f);
        private Texture2D _brickTexture;
        
        // Deferred rendering
        // Render targets
        private RenderTarget2D _colorRenderTarget;
        private RenderTarget2D _normalRenderTarget;
        private RenderTarget2D _depthRenderTarget;
        private RenderTarget2D _lightRenderTarget;
        
        private Effect _blinnPhongEffect;
        private Effect _gBufferEffect;
        private Effect _clearBufferEffect;
        private Effect _combineEffect;
        
        private FullScreenQuad _fullScreenQuad;

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
            
            _fullScreenQuad = new FullScreenQuad(GraphicsDevice);
            
            _freeCamera = new FreeCamera(GraphicsDevice.Viewport.AspectRatio, _cameraInitialPosition);
            
            _sphereWorld = Matrix.CreateScale(_sphereScale) * Matrix.CreateTranslation(_spherePosition);
            
            _quadWorld = Matrix.CreateTranslation(_quadPosition);
            _quad = new QuadPrimitive(GraphicsDevice, _quadScale);

            base.Initialize();
        }

        protected override void LoadContent()
        {
            _spriteBatch = new SpriteBatch(GraphicsDevice);
            
            _blinnPhongEffect = Content.Load<Effect>(ContentFolderEffects + "DirectionalLight");
            _gBufferEffect = Content.Load<Effect>(ContentFolderEffects + "RenderGBuffer");
            _clearBufferEffect = Content.Load<Effect>(ContentFolderEffects + "ClearGBuffer");
            _combineEffect = Content.Load<Effect>(ContentFolderEffects + "CombineFinal");
            LoadRenderTargets();

            _sphereModel = Content.Load<Model>(ContentFolder3D + "sphere");
            _brickTexture = Content.Load<Texture2D>(ContentFolderTextures + "brick");
            LoadEffectOnMesh(_sphereModel, _gBufferEffect);
            
            base.LoadContent();
        }
        
        private void LoadRenderTargets()
        {
            _colorRenderTarget = new RenderTarget2D(GraphicsDevice, GraphicsDevice.Viewport.Width,
                GraphicsDevice.Viewport.Height, false, SurfaceFormat.Color, DepthFormat.Depth24);

            _normalRenderTarget = new RenderTarget2D(GraphicsDevice, GraphicsDevice.Viewport.Width,
                GraphicsDevice.Viewport.Height, false, SurfaceFormat.Color, DepthFormat.None);

            _depthRenderTarget = new RenderTarget2D(GraphicsDevice, GraphicsDevice.Viewport.Width,
                GraphicsDevice.Viewport.Height, false, SurfaceFormat.Single, DepthFormat.None);
            
            _lightRenderTarget = new RenderTarget2D(GraphicsDevice, GraphicsDevice.Viewport.Width, 
                GraphicsDevice.Viewport.Height, false, SurfaceFormat.Color, DepthFormat.None);
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
            var keyboardState = Keyboard.GetState();
            
            SetGBuffer();
            DrawQuad();
            DrawSphere();
            ResolveGBuffer();
            DrawLights(gameTime);
            
            if (keyboardState.IsKeyDown(Keys.R))
            {
                DrawRenderTargets();
            }

            base.Draw(gameTime);
        }
        
        private void DrawRenderTargets()
        {
            var halfWidth = GraphicsDevice.Viewport.Width / 2;
            var halfHeight = GraphicsDevice.Viewport.Height / 2;
            _spriteBatch.Begin();
            _spriteBatch.Draw(_colorRenderTarget, new Rectangle(0, 0, halfWidth, halfHeight), Color.White);
            _spriteBatch.Draw(_normalRenderTarget, new Rectangle(0, halfHeight, halfWidth, halfHeight), Color.White);
            _spriteBatch.Draw(_depthRenderTarget, new Rectangle(halfWidth, 0, halfWidth, halfHeight), Color.White);
            _spriteBatch.Draw(_lightRenderTarget, new Rectangle(halfWidth, halfHeight, halfWidth, halfHeight), Color.White);
            _spriteBatch.End();
        }
        
        private void DrawLights(GameTime gameTime)
        {
            GraphicsDevice.SetRenderTarget(_lightRenderTarget);
            GraphicsDevice.Clear(Color.Transparent);
            GraphicsDevice.BlendState = BlendState.AlphaBlend;
            GraphicsDevice.DepthStencilState = DepthStencilState.None;
            
            DrawDirectionalLight(new Vector3(-250f, 100f, 0f), Color.White);
            DrawDirectionalLight(new Vector3(250f, 100f, 0f), Color.SkyBlue);
            
            GraphicsDevice.BlendState = BlendState.Opaque;
            GraphicsDevice.DepthStencilState = DepthStencilState.None;            
            GraphicsDevice.RasterizerState = RasterizerState.CullCounterClockwise;
            
            GraphicsDevice.SetRenderTarget(null);
            
            //Combine everything
            _combineEffect.Parameters["ColorMap"].SetValue(_colorRenderTarget);
            _combineEffect.Parameters["LightMap"].SetValue(_lightRenderTarget);
            
            _fullScreenQuad.Draw(_combineEffect);

            var fps = (1000 / gameTime.ElapsedGameTime.TotalMilliseconds);
            fps = Math.Round(fps, 0);
            Window.Title = "Drawing 2 lights at " + fps + " FPS";
        }
        
        private void DrawDirectionalLight(Vector3 lightPosition, Color color)
        {
            _blinnPhongEffect.Parameters["ColorMap"].SetValue(_colorRenderTarget);
            _blinnPhongEffect.Parameters["NormalMap"].SetValue(_normalRenderTarget);
            _blinnPhongEffect.Parameters["DepthMap"].SetValue(_depthRenderTarget);

            _blinnPhongEffect.Parameters["LightPosition"].SetValue(lightPosition);
            _blinnPhongEffect.Parameters["LightColor"].SetValue(color.ToVector3());

            _blinnPhongEffect.Parameters["EyePosition"].SetValue(_freeCamera.Position);
            _blinnPhongEffect.Parameters["InvertViewProjection"].SetValue((_freeCamera.View * _freeCamera.Projection));
            
            _fullScreenQuad.Draw(_blinnPhongEffect);
        }
        
        private void SetGBuffer()
        {
            GraphicsDevice.SetRenderTargets(_colorRenderTarget, _normalRenderTarget, _depthRenderTarget);
        }
        
        private void ResolveGBuffer()
        {
            GraphicsDevice.SetRenderTargets(null);
        }
        
        private void ClearGBuffer()
        {
            _fullScreenQuad.Draw(_clearBufferEffect);
        }

        private void DrawQuad()
        {
            GraphicsDevice.DepthStencilState = DepthStencilState.Default;
            GraphicsDevice.RasterizerState = RasterizerState.CullCounterClockwise;
            GraphicsDevice.BlendState = BlendState.Opaque;
            
            _gBufferEffect.Parameters["World"].SetValue(_quadWorld);
            _gBufferEffect.Parameters["View"].SetValue(_freeCamera.View);
            _gBufferEffect.Parameters["Projection"].SetValue(_freeCamera.Projection);
            _gBufferEffect.Parameters["InverseTransposeWorld"].SetValue(Matrix.Transpose(Matrix.Invert(_quadWorld)));
            _gBufferEffect.Parameters["Texture"].SetValue(_brickTexture);
            
            _quad.Draw(_gBufferEffect);
        }

        private void DrawSphere()
        {
            GraphicsDevice.DepthStencilState = DepthStencilState.Default;
            GraphicsDevice.RasterizerState = RasterizerState.CullCounterClockwise;
            GraphicsDevice.BlendState = BlendState.Opaque;
            
            _gBufferEffect.Parameters["World"].SetValue(_sphereWorld);
            _gBufferEffect.Parameters["View"].SetValue(_freeCamera.View);
            _gBufferEffect.Parameters["Projection"].SetValue(_freeCamera.Projection);
            _gBufferEffect.Parameters["InverseTransposeWorld"].SetValue(Matrix.Transpose(Matrix.Invert(_sphereWorld)));
            _gBufferEffect.Parameters["Texture"].SetValue(_brickTexture);
            
            foreach (var mesh in _sphereModel.Meshes)
            {
                mesh.Draw();
            }
        }
    }
}