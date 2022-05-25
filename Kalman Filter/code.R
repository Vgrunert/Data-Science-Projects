##################################################################################################################
##################################################################################################################
##################################################################################################################


# Author: Vincent Grunert
# Content: R Code generated the simulations for 
# "Extended- Kalman and Particle Filter" 



##################################################################################################################
##################################################################################################################
##################################################################################################################


##################################################################################################################
#############################      FUNCTION     DEFINITIONS      #################################################
##################################################################################################################


#####
# generating samples from the multivariate normal distribution 
mvnorm <- function(n, mu, covar){
    return((t(chol(covar)) %*% rnorm(n)) + mu)
}
#####

#####
# kalman filter equations inplementation
# the implementation is slightly different for vector inputs then matrix inputs
# which is why it requires two different "inner" implementations
kalman_filter <- function(measurements, stateTransition, processNoise,
    outputMatrix, measurementNoise){    

    # vector input 
    if(is.vector(measurements)){

        # number of measurements
        n <- length(measurements)

        # number of states
        n_state <- ncol(stateTransition)

        # init state matrix
        state <- matrix(0, ncol=n_state, nrow=n)

        # use first measurement as init state
        state[1, ] <- c(measurements[1], rep(0, n_state - 1))

        # init state covariance matrix
        S <- diag(rep(10, n_state))

        # kalman filter equations 
        for(i in 2:n){
            # predict
            m_ <- stateTransition %*% state[i-1, ]
            S_ <- stateTransition %*% S %*% t(stateTransition) + processNoise

            # update
            S <- outputMatrix %*% S_ %*% t(outputMatrix) + measurementNoise
            K <- S_ %*% t(outputMatrix) %*% solve(S)
            m <- m_ + K %*% (measurements[i] - outputMatrix %*% m_)
            S <- S_ - K %*% S %*% t(K)

            # save
            state[i,] <- m
        }
    }
    if(is.matrix(measurements)){

        # number of measurements
        n_measure <- nrow(measurements)

        # number of states
        n_state <- ncol(stateTransition)

        # init state 
        state <- matrix(0, ncol=n_state, nrow=n_measure)

        # use first measurement as init state
        state[1, ] <- c(measurements[1,], rep(0, n_state - ncol(measurements)))

        # state covariance matrix
        S <- diag(rep(10, n_state))

        # kalman filter equations
        for(i in 2:n){
            # predict
            m_ <- stateTransition %*% state[i-1, ]
            S_ <- stateTransition %*% S %*% t(stateTransition) + processNoise

            # update
            S <- outputMatrix %*% S_ %*% t(outputMatrix) + measurementNoise
            K <- S_ %*% t(outputMatrix) %*% solve(S)
            m <- m_ + K %*% (measurements[i,] - outputMatrix %*% m_)
            S <- S_ - K %*% S %*% t(K)

            # save
            state[i,] <- m
        }
    }
    # return state  
    return(state)
}
#####

#####
# functions usind in deriving the recursive non linear regression extended kalman-filter solution
# exponential model with one variable
h <- function(x, beta) { exp(x*beta) }

# derivative of the exponential function w.r.t. the state
H <- function(x, beta) { h(x, beta)/x }
#####

#####
# functions for the importance sampling example
# function of the random variable
f <- function(x) {cos(x)^2 }

# normal density
d_norm  <- function(x, mu=0, sig=1) {1/sqrt(2*pi)*exp(- (x-mu)^2/(2*sig^2))}

# laplace distribution density
dlaplace <- function(x, b=1, mu =0){ 1/(2*b)*exp(-abs(x-mu)/b)}

# generate random variables according to the laplace distribution
rlaplace <- function(b, u){
    -b*sign(u-0.5)*log(1 - 2*abs(u-0.5))
}
#####

#####
# state transition function for the particle filter simulation
state_update <- function(x,t) {  0.5*x + 25*x/(1 + x^2) + 8*cos(1.2*(t-1)) }

# measurement / process transition function for the particle filter simulation
measurement_update <- function(x) { x^2/20 }
#####

#####
# state transition function for the particle filter simulation
stochastic_volatility_state  <- function(x, a, b) { a + b * x }

# measurement / process transition function for the particle filter simulation
stochastic_volatility_process  <- function(state) { exp(state) }
#####


##################################################################################################################
#############################    FUNCTION   DEFINITIONS   END    #################################################
##################################################################################################################




##################################################################################################################
#############################      KALMAN FILTER SIMULATIONS     #################################################
##################################################################################################################

# generate n constant measurements whose mean changes after n/2 measurements
# random seed
set.seed(0)

# init n
n <- 1000

# save results
time_var_const_mean <- numeric(n)

# generate time depended constant data with gaussian noise
for(i in 1:n){
        time_var_const_mean[i] <- rnorm(1, mean = 5, sd = 0.1)
    if( i < n/2){
    } else {
        time_var_const_mean[i] <- rnorm(1, mean = 10, sd = 0.1)
    }
}

# apply the kalman filter
kf_const_time_var_mean <- kalman_filter( measurements = time_var_const_mean, stateTransition = matrix(c(1,1, 0,1), ncol = 2), 
    processNoise = diag(rep(1,2)), outputMatrix = matrix(c(1,0), ncol = 2),  measurementNoise = matrix(1, ncol=1)
)

# save plots
jpeg("./mean_shift.jpg")
plot(time_var_const_mean, pch=19, 
    main = "Kalman-Filter Mean-Shift Model",
    xlab = "Time",
    ylab = "Measurements")
lines(kf_const_time_var_mean[,1], col='red')
dev.off()  


# second k-f example using sine function with additive gaussian noise 
set.seed(0)

# generate data
sine <- sin(seq(-pi, pi, length.out=n)) + rnorm(n,sd=0.5)

# apply k-f
kf_sine <- kalman_filter(measurements = sine, stateTransition = matrix(c(1,1, 0,1), ncol = 2), processNoise = diag(rep(1,2)), 
    outputMatrix = matrix(c(1,0), ncol = 2), measurementNoise = matrix(1, ncol=1)
)

# save grafics
jpeg("./sine.jpg")
plot(sine, pch=19, 
    main = "Kalman-Filter Sine Function",
    xlab = "Time",
    ylab = "Measurements")
lines(kf_sine[,1], col='red')
dev.off()  

# generate two dimensional random walk, where the current position depends only on the previous one
set.seed(0)

# save data
random_walk <- matrix(0, ncol=2, nrow=n)

# generte random walk
for(i in 2:n){
    random_walk[i, 1] <- random_walk[i-1, 1] + rnorm(1, sd=0.5)
    random_walk[i, 2] <- random_walk[i-1, 2] + rnorm(1, sd=0.5)
}

# apply k-f
kf_random_walk <- kalman_filter(measurements = random_walk, stateTransition = matrix(c(1,0,0,0, 0,1,0,0, 1,0,1,0, 0,1,0,1), ncol = 4), 
    processNoise = diag(rep(1,4)), outputMatrix = matrix(c(1,0, 0,1, 0,0, 0,0), ncol = 4),  measurementNoise = diag(c(1,1))
)

# save grafics
jpeg("./random_walk.jpg")
plot(random_walk, type='l',, 
    main = "Kalman-Filter Random Walk",
    xlab = "X Direction",
    ylab = "Y Direction")
lines(kf_random_walk[,1], kf_random_walk[,2], col='red', lty=2)
dev.off()


# recursive linear regression
set.seed(0)
# explantatory variables with intercept
X <- cbind(rep(1, n), rnorm(n))

# true state
beta <- c(2, 6)

# gaussian model
y_lin <- rnorm(n, mean= X%*%beta, 1)

# save state
beta_lin_est  <- matrix(0, ncol=n, nrow=2)

# state covariance
Sig <- diag(c(1,1))

# not using the kalman filter function because for recursive regression
# the predict step is not required, thus there is no state transition in this model
# run the equations
for(i in 2:n){
    S  <- X[i,,drop=FALSE] %*% Sig %*% t(X[i,,drop=FALSE]) + 1
    K  <- Sig %*% t(X[i,,drop=FALSE]) / as.numeric(S)
    beta_lin_est[,i]  <- beta_lin_est[,i-1] + K %*% (y_lin[i] - X[i, ] %*% beta_lin_est[,i-1])    
    Sig <- Sig - K%*%S%*%t(K)
}

# save plot
jpeg("./Recursive_Lin_Red.jpg")
plot(X[,2], y_lin,
    main = "Measurement-Space",
    xlab = "X",
    ylab = "y"
)
abline(lm(y_lin ~ X - 1 )$coefficients[1], lm(y_lin ~ X - 1 )$coefficients[2], lw=5)
abline(beta_lin_est[1, n], beta_lin_est[2,n], col = "red")
dev.off()


# state space
jpeg("./Recursive_State_Space.jpg")
plot(beta_lin_est[1,-1], beta_lin_est[2,-1], 
    main = "State-Space Evolution",
    xlab = "Intercept",
    ylab = "x",
    type = "l"
)
points(beta_lin_est[1, 2], beta_lin_est[2,2], pch=19)
text(beta_lin_est[1, 2], beta_lin_est[2,2], "First", adj = c(-0.3, 0.5))
points(beta_lin_est[1, n], beta_lin_est[2,n], pch=19)
text(beta_lin_est[1, n], beta_lin_est[2,n], "Last", adj = c(1.5, 0.5))
abline(v = 2, lty = 2, lw = 0.5, col = "red")
abline(h = 6, lty = 2, lw = 0.5, col = "red")
dev.off()

##################################################################################################################
#############################    KALMAN FILTER SIMULATIONS END   #################################################
##################################################################################################################


##################################################################################################################
############################# EXTENDED KALMAN FILTER SIMULATION  #################################################
##################################################################################################################

# recursive non linear regression
# additional observations
# first try
n <- 1000

# state of the model
beta_non_lin_est  <- numeric(n+1)

# generate covariable, just standard normal observations 
set.seed(0)
x  <- sort(rnorm(n))

# generate gaussian measurements
y_non_lin <- rnorm(n, mean= h(x, 0.9), 1)

# state variance 
Sig <- 1

# run the calculation for the extended kalman filter according to formula
for(i in 1:n){
    v  <- y_non_lin[i] - h(x[i], beta_non_lin_est[i])
    H <- h(x[i], beta_non_lin_est[i])/x[i]
    S  <- H * Sig * H + 1
    K  <- Sig * H / as.numeric(S)
    beta_non_lin_est[1+i]  <- beta_non_lin_est[i] + K * v
    Sig <- Sig - K*S*t(K)
}

# save grafics
jpeg("./non_lin_reg.jpg")
plot(x, y_non_lin, 
    main = "Measurements",
    xlab = "x",
    ylab = "y"
)
lines(x, h(x, beta_non_lin_est[-n]), col='red')
dev.off()

jpeg("./non_lin_state_space.jpg")
plot(beta_non_lin_est, type='l',
 main = "State-Space",
 xlab = "Iteration",
 ylab = "State"
)
abline(h = 0.9, col = 'red', lty = 2)
dev.off()

# recursive non linear regression
# additional observations
# second try increase n
n <- 10000

# state of the model
beta_non_lin_est  <- numeric(n+1)

# generate covariable, just standard normal observations 
set.seed(0)
x  <- sort(rnorm(n))

# generate gaussian measurements
y_non_lin <- rnorm(n, mean= h(x, 0.9), 1)

# state variance 
Sig <- 1

# run the calculation for the extended kalman filter according to formula
for(i in 1:n){
    v  <- y_non_lin[i] - h(x[i], beta_non_lin_est[i])
    H <- h(x[i], beta_non_lin_est[i])/x[i]
    S  <- H * Sig * H + 1
    K  <- Sig * H / as.numeric(S)
    beta_non_lin_est[1+i]  <- beta_non_lin_est[i] + K * v
    Sig <- Sig - K*S*t(K)
}

# save grafics
jpeg("./non_lin_reg_large_n.jpg")
plot(x, y_non_lin, 
    main = "Measurements",
    xlab = "x",
    ylab = "y"
)
lines(x, h(x, beta_non_lin_est[-n]), col='red')
dev.off()

jpeg("./non_lin_state_space_large_n.jpg")
plot(beta_non_lin_est, type='l',
 main = "State-Space",
 xlab = "Iteration",
 ylab = "State"
)
abline(h = 0.9, col = 'red', lty = 2)
dev.off()
##################################################################################################################
############################# EXTENDED KALMAN FILTER SIMULATION END ##############################################
##################################################################################################################


##################################################################################################################
#############################     PARTICLE FILTER SIMULATION     #################################################
##################################################################################################################


# importance sampling example

set.seed(0)
# generate x-values in the range of -3,3
x <- seq(-3,3,by=0.1)
jpeg("Importance_Sampling_Comp.jpg")
# plot importance densities and target function
plot(x, f(x)*dnorm(x), type='l', xlim=c(-5,5), ylim=c(0,0.5), 
    main="Comparing Distributions",
    ylab = "cos(x^2) * dnorm"
)
lines(x, dlaplace(x),col='red')
lines(x, dnorm(x),col='green')
lines(x, dunif(x, -3,3),col='blue')
dev.off()

# perform monte carlo integration to calculate the expected values
n <- length(x)
set.seed(0)
norm_samples  <- rnorm(n)
lapl_samples <- rlaplace(1, runif(n))
unif_samples_2 <- runif(n, -3, 3)
mean( f(lapl_samples) * dnorm(lapl_samples) / dlaplace(lapl_samples, 1, 0))
mean( f(unif_samples_2) * dnorm(unif_samples_2) / dunif(unif_samples_2, -3, 3))
mean( f(norm_samples) * dnorm(norm_samples) / dnorm(norm_samples))

# end example


# particle filter simulatin example 1

# init state
x <- 0.1
# process noise
x_N <- 1 
# measurement noise
x_R <- 1
# duration
T <- 100
# num particles
N <- 1000
# init var
V <- 2

# save variables
z_out <- numeric(T)
x_out <- numeric(T)
x_est <- numeric(T)
x_est_out <- numeric(T)
weight <- numeric(N)


set.seed(0)
# init particles
particles <- rnorm(N, x, sqrt(V))

for(t in 1:T){
    x  <- rnorm(1, state_update(x,t-1), x_N)
    z <- rnorm(1, measurement_update(x), 2)

    for(i in 1:N){
        particles[i] <- rnorm(1, state_update(particles[i],t-1), x_N)
        z_update <- measurement_update(particles[i])
        weight[i] <- dnorm(z, z_update, 2)
    }
    weight  <- weight / sum(weight)
    particles <- sample(particles, size=N, replace=TRUE, prob=weight)
    x_est <- mean(particles)
    x_out[t] <- x
    z_out[t] <- z
    x_est_out[t] <- x_est
}

jpeg("./Particle_Filter_Model_State.jpg")
plot(x_out, type='l', main="State Developement", xlab= "Iteration", ylab = "State")
lines(x_est_out, col='red', lty=2)
dev.off()

jpeg("./Particle_Filter_Model_Measurement.jpg")
plot(z_out, type='l', main="Position Developement", xlab= "Iteration", ylab = "Position")
lines(measurement_update(x_est_out), col='red', lty=2)
dev.off()


# example ends


# exaple stochastic volatility model

# read data
vix_orig <- read.csv("./Seminar/paper/VIXCLS.csv")

# inspect data
dim(vix_orig)
head(vix_orig)
tail(vix_orig)

# missing values?
vix <- as.numeric(as.character(vix_orig[,2]))

# remove missing values
vix <- vix[!is.na(vix)]

# init variables
n <- 1000
T  <- length(vix)

# model parameters
a <- 0.69
b <- 1
sig_v <- 1.12
B <- 0.89
sig_w <- 0.78

# save estimate
x_est_out <- numeric(T)
# state <-numeric(T)

set.seed(0)

# generate particles
particles <- rnorm(n, sd = sig_v)

# perform calculations
for(t in 1:T){
    particles <- rnorm(n, mean=stochastic_volatility_state(particles, a, b), sd = sqrt(sig_v))
    z_update <- stochastic_volatility_process(particles)
    weight <- dnorm(vix[t], z_update, sig_w)
    # weight <- weight * dnorm(z[t], z_update, sig_w)
    weight  <- weight / sum(weight)
    particles <- sample(particles, size=n, replace=TRUE, prob=weight)
    x_est <- mean(particles)
    x_est_out[t] <- x_est
}

# save results
jpeg("./Particle_Filter_Vix.jpg")
plot(vix, type='l', main="Vix", xlab= "Time", ylab = "Value")
lines(stochastic_volatility_process(x_est_out), col='red', lty=2)
dev.off()

jpeg("./Particle_Filter_Vix_Short.jpg")
plot(vix[1:50], type='l', main="Vix First 50 Observations", xlab= "Time", ylab = "Value")
lines(stochastic_volatility_process(x_est_out)[1:50], col='red', lty=2)
dev.off()



##################################################################################################################
#############################   PARTICLE FILTER SIMULATION END   #################################################
##################################################################################################################


##################################################################################################################
##################################################################################################################
##################################################################################################################
#############################       END      OF      CODE        #################################################
##################################################################################################################
##################################################################################################################
##################################################################################################################
