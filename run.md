## start db

- docker compose up -d julia-db
- docker compose down

## start backend server 

- julia --project=. -e "using Pkg; Pkg.instantiate()"
- julia --project=. -e 'using Pkg; Pkg.resolve()'
- cd "h:\Rahul Prasad 01\bot\JuliaOS\backend"; julia start_enhanced_market_making.jl
- cd "h:\Rahul Prasad 01\bot\JuliaOS\backend"; julia run_server.jl

## pushed to github

- git add .
- git commit -m "message"
- git push myfork main 