package utils

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestStringStack_PushAndPop(t *testing.T) {
	stack := StringStack{}
	
	stack.Push("first")
	stack.Push("second")
	stack.Push("third")
	
	assert.Equal(t, "third", stack.Pop())
	assert.Equal(t, "second", stack.Pop())
	assert.Equal(t, "first", stack.Pop())
}

func TestStringStack_PopEmptyStack(t *testing.T) {
	stack := StringStack{}
	
	result := stack.Pop()
	
	assert.Equal(t, "", result)
}

func TestStringStack_IsEmpty(t *testing.T) {
	stack := StringStack{}
	
	assert.True(t, stack.IsEmpty())
	
	stack.Push("item")
	assert.False(t, stack.IsEmpty())
	
	stack.Pop()
	assert.True(t, stack.IsEmpty())
}

func TestStringStack_Clear(t *testing.T) {
	stack := StringStack{}
	
	stack.Push("first")
	stack.Push("second")
	stack.Push("third")
	
	stack.Clear()
	
	assert.True(t, stack.IsEmpty())
	assert.Equal(t, "", stack.Pop())
}

func TestStringStack_MultipleOperations(t *testing.T) {
	stack := StringStack{}
	
	stack.Push("a")
	stack.Push("b")
	assert.Equal(t, "b", stack.Pop())
	
	stack.Push("c")
	stack.Push("d")
	assert.Equal(t, "d", stack.Pop())
	assert.Equal(t, "c", stack.Pop())
	assert.Equal(t, "a", stack.Pop())
	assert.True(t, stack.IsEmpty())
}
