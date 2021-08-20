module Environment

using Flux, DifferentialEquations, LinearAlgebra

export evaluate, sensor_value, Dense

R(α::Float64) = [cos(α) -sin(α); sin(α) cos(α)]
function sensor_location(x::Float64, y::Float64, α::Float64, lx::Float64, ly::Float64)
    return [x, y] + R(α)*[lx, ly]
end

function sensor_value(u::Vector{Float64}, lx::Float64, ly::Float64)
    return 1.0 / norm(sensor_location(u[1], u[2], u[3], lx, ly))^2
end

function robot_eq!(du::Vector{Float64}, u::Vector{Float64}, p::Tuple{Tuple{Float64,Float64},Tuple{Float64,Float64},Dense{typeof(identity),Array{Float64,2},Array{Float64,1}}}, t::Float64)
    m = p[3]([sensor_value(u, p[1]...), sensor_value(u, p[2]...)])
    v = sum(m)/2
	du[1] = v*cos(u[3])
	du[2] = v*sin(u[3])
	du[3] = diff(m)[1]
end

function evaluate(idx::Int, p::Tuple{Tuple{Float64,Float64},Tuple{Float64,Float64},Dense{typeof(identity),Array{Float64,2},Array{Float64,1}}})
    len = 4.0/sqrt(2.0)
    u0 = [[len, len, 0.0], [len, -len, 0.0], [-len, -len, 0.0], [-len, len, 0.0]]
    tspan = (0.0, 500.0)
    prob = ODEProblem(robot_eq!,u0[idx],tspan,p)
    sol = solve(prob, Euler(), dt=0.05)
    return sol.u
end

end # module