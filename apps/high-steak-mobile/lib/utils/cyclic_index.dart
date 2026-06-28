int cyclicPreviousIndex(int current, int length) {
  if (length <= 0) return 0;
  return (current - 1 + length) % length;
}

int cyclicNextIndex(int current, int length) {
  if (length <= 0) return 0;
  return (current + 1) % length;
}
