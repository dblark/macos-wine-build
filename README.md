Install dependencies: (See also <https://github.com/Gcenx/macports-wine/blob/main/emulators/wine-devel/Portfile>)

for build:

```bash
brew install bison \
             gettext \
             mingw-w64 \
             pkg-config
brew install --cask gstreamer-development
```

for runtime:

```bash
brew install freetype \
             gettext \
             gnutls \
             sdl2
brew install --cask gstreamer-runtime
```

and ccache:

```bash
brew install ccache
```

Then run `./build.sh`.

Copy the bundle `$ENGINE_NAME.tar.7z` to `$HOME/Library/Applications Support/Kegworks/Engines` to use the engine.

Thanks to

<https://github.com/Gcenx/macports-wine>

<https://github.com/marzent/wine-msync>

<https://github.com/Kegworks-App/Kegworks>

<https://www.codeweavers.com/crossover>
