/** @type {import('next').NextConfig} */
const nextConfig = {
  env: {
    JULIA_API_URL: process.env.JULIA_API_URL || 'http://127.0.0.1:8052',
  },
  async rewrites() {
    return [
      {
        source: '/api/julia/:path*',
        destination: `${process.env.JULIA_API_URL || 'http://127.0.0.1:8052'}/api/:path*`,
      },
    ]
  },
}

module.exports = nextConfig
