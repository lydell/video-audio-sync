const ExtractPlugin = require("extract-text-webpack-plugin");
const HtmlWebpackPlugin = require("html-webpack-plugin");
const ScriptExtHtmlWebpackPlugin = require("script-ext-html-webpack-plugin");
const path = require("path");
const webpack = require("webpack");

const DEBUG = process.env.NODE_ENV !== "production";
const OUTPUT_PATH = path.resolve(__dirname, "build");
const PUBLIC_PATH = "/";

const constants = {
  "process.env.NODE_ENV": JSON.stringify(DEBUG ? "development" : "production"),
};

const extractCss = new ExtractPlugin({
  filename: DEBUG ? "[name].css" : "[name].[contenthash].css",
  disable: DEBUG,
});

module.exports = {
  context: path.resolve(__dirname, "frontend"),

  entry: {
    main: "./js/main.js",
  },

  output: {
    filename: DEBUG ? "[name].js" : "[name].[chunkhash].js",
    chunkFilename: DEBUG ? "[name].js" : "[name].[chunkhash].js",
    path: OUTPUT_PATH,
    publicPath: PUBLIC_PATH,
    pathinfo: DEBUG,
  },

  devtool: DEBUG ? "cheap-module-source-map" : "source-map",

  devServer: {
    hot: true,
    contentBase: OUTPUT_PATH,
    publicPath: PUBLIC_PATH,
    historyApiFallback: true,
    overlay: true,
    host: "0.0.0.0",
    port: 8000,
    stats: "errors-only",
  },

  module: {
    noParse: /\.elm$/,
    rules: [
      {
        test: /\.js$/,
        exclude: [/elm-stuff/, /node_modules/],
        use: {
          loader: "babel-loader",
        },
      },
      {
        test: /\.elm$/,
        exclude: [/elm-stuff/, /node_modules/],
        use: [
          {
            loader: "elm-hot-loader",
          },
          {
            loader: "elm-webpack-loader",
          },
        ],
      },
      {
        test: /\.css$/,
        use: extractCss.extract({
          fallback: {
            loader: "style-loader",
            options: {
              sourceMap: true,
            },
          },
          use: [
            {
              loader: "css-loader",
              options: {
                sourceMap: true,
              },
            },
          ],
        }),
      },
      {
        test: /\.(jpg|png|svg|eot|woff2?|ttf)$/,
        use: {
          loader: "file-loader",
        },
      },
    ],
  },

  plugins: [
    !DEBUG &&
      new webpack.LoaderOptionsPlugin({
        minimize: true,
        debug: false,
      }),

    new webpack.DefinePlugin(constants),

    extractCss,

    DEBUG && new webpack.HotModuleReplacementPlugin(),

    DEBUG
      ? new webpack.NamedModulesPlugin()
      : new webpack.HashedModuleIdsPlugin(),

    new webpack.optimize.CommonsChunkPlugin({
      name: "vendor",
      minChunks: module =>
        module.context && module.context.includes("node_modules"),
    }),

    new webpack.optimize.CommonsChunkPlugin({
      name: "manifest",
      minChunks: Infinity,
    }),

    !DEBUG && new webpack.optimize.UglifyJsPlugin(),

    new HtmlWebpackPlugin({
      template: "./index.ejs",
      minify: DEBUG
        ? false
        : {
            removeComments: true,
            collapseWhitespace: true,
            minifyCSS: true,
            minifyJS: true,
            removeRedundantAttributes: true,
            removeScriptTypeAttributes: true,
            removeStyleLinkTypeAttributes: true,
          },
    }),

    new ScriptExtHtmlWebpackPlugin({
      // Inlining breaks CSS HMR after the first JS change.
      inline: !DEBUG && /manifest/,
      defaultAttribute: "defer",
    }),
  ].filter(Boolean),
};
