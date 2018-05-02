export function has(object, key) {
  return Object.hasOwnProperty.call(object, key);
}

export function partition(array, fn) {
  const left = [];
  const right = [];

  for (const item of array) {
    if (fn(item)) {
      left.push(item);
    } else {
      right.push(item);
    }
  }

  return [left, right];
}
