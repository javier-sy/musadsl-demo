# Demo 18: Parameter Automation - Números Primos
#
# Números primos para períodos no repetitivos
# Usados con SIN() para crear automatizaciones que no se repiten exactamente

PRIMES = [
  2, 3, 5, 7, 11, 13, 17, 19, 23, 29,       # 0-9
  31, 37, 41, 43, 47, 53, 59, 61, 67, 71,   # 10-19
  73, 79, 83, 89, 97, 101, 103, 107, 109, 113  # 20-29
].freeze

# Ejemplos de uso:
# PRIMES[5]  => 13 (buen período corto)
# PRIMES[10] => 31 (período medio)
# PRIMES[15] => 53 (período largo)
