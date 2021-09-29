# Python equivalent of the listings in "A High-Level Benchmark" 
# (Byte magazine, September 1981).
#
# Counts the number of primes between 3 and 16381. The last element
# of the array represents the primality of (2 * size) + 3.
#
# The original was not intended to be a reference implementation of 
# the Sieve of Erastothenes. (It doesn't count two as a prime number, 
# and omits optimizations Erastothenes knew about.) Perhaps better 
# thought of as a synthetic benchmark based on the Sieve.

size = 8190
sizep1 = 8191

flags = [True] * sizep1

print("1 iterations")
for iter in range(0, 1):
    count = 0
    for i in range(0, sizep1):
        flags[i] = True
    
    for i in range(0, sizep1):
        if flags[i]:
            prime = i + i + 3
            k = i + prime
            while k <= size:
                flags[k] = False
                k = k + prime
            
            count = count + 1
            #print(prime)

print(count, " primes")


