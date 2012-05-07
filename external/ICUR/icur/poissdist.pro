function poissdist,mu,x
m=float(mu)
pp=(m^x)/float(factorial(x))*exp(-m)
return,pp
end
