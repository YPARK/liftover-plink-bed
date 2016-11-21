set -u
set -e

chr=$1
FLAGS=""

if [[ "$chr" == *"X"* ]] ; then
  FLAGS="-X"
fi
if [[ "$chr" == *"Y"* ]] ; then
  FLAGS="$FLAGS -Y"
fi
if [[ "$chr" == *"MT"* ]] ; then
  FLAGS="$FLAGS -MT"
fi

echo "chr=$chr flags=$FLAGS"
