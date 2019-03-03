def main(default=601)
    out = Array.new(default) {Array.new(default, [0, 0, 0])}
    transform = ident(4)
    edges = Array.new(0)
    file_data = []
    File.open('script.txt', 'r') {|file|
        file.each_line { |line|
            file_data.append(line.strip)
        }
    }
    while file_data.length > 0 
        current = file_data.shift # pop first element off array
        if current == 'line'
            coords = file_data.shift.split(" ")
            add_edge(edges, *(coords.map {|x| x.to_f}))
        elsif current == 'ident'
            transform = ident(4)
        elsif current == 'scale'
            factors = file_data.shift.split(" ")
            mult(scale(*factors), transform)
        elsif current == 'move'
            dists = file_data.shift.split(" ")
            mult(trans(*dists), transform)
        elsif current == 'rotate'
            args = file_data.shift.split(" ")
            mult(rot(*args), transform)
        elsif current == 'apply'
            mult(transform, edges)
        elsif current == 'display'
            out = Array.new(default) {Array.new(default, [0, 0, 0])}
            draw_matrix(out, edges)
            save_ppm(out, default)
            `display image.ppm` # ` ` runs terminal commands
        elsif current == 'save'
            out_file = file_data.shift
            out = Array.new(default) {Array.new(default, [0, 0, 0])}
            draw_matrix(out, edges)
            save_ppm(out, default)
            `convert image.ppm #{out_file}`
        end
    end
end

def save_ppm(ary, dim)
    File.open('image.ppm', 'w') {|file|
        file.write("P3\n#{dim}\n#{dim}\n255\n")
        ary.length.times {|i|
            ary[i].length.times{|j|
                3.times {|k|
                    file.write(ary[i][j][k].to_s + ' ')
                }
            }
        }
    }
end

# transformation stuff

def trans(*args) # only takes the first 3 arguments
    new = Array.new(4) {Array.new(4, 0.0)}
    4.times {|i|
        new[3][i] = args[i].to_f
        new[i][i] = 1.0
    }
    return new
end

def scale(*args)
    new = Array.new(4) {Array.new(4, 0.0)}
    3.times {|i|
        new[i][i] = args[i].to_f
    }
    new[3][3] = 1.0
    return new
end

def rot(axis, theta)
    if axis == 'x'
        return rot_x(theta.to_f)
    elsif axis == 'y'
        return rot_y(theta.to_f)
    elsif axis == 'z'
        return rot_z(theta.to_f)
    end
end

def rot_x(_theta)
    new = ident(4)
    theta = _theta * Math::PI / 180.0
    new[1][1] = Math.cos(theta)
    new[1][2] = Math.sin(theta)
    new[2][1] = -Math.sin(theta)
    new[2][2] = Math.cos(theta)
    return new
end

def rot_y(_theta)
    new = ident(4)
    theta = _theta * Math::PI / 180.0
    new[0][0] = Math.cos(theta)
    new[0][2] = Math.sin(theta)
    new[2][0] = -Math.sin(theta)
    new[2][2] = Math.cos(theta)
    return new
end

def rot_z(_theta)
    new = ident(4)
    theta = _theta * Math::PI / 180.0
    new[0][0] = Math.cos(theta)
    new[0][1] = Math.sin(theta)
    new[1][0] = -Math.sin(theta)
    new[1][1] = Math.cos(theta)
    return new
end

# edge matrix stuff
=begin
def mult(a, b)
    new = Array.new(b.length) {Array.new(a[0].length, 0)}
    a[0].length.times {|i|
        b.length.times {|j|
            total = 0
            a.length.times {|k|
                total += a[k][i] * b[j][k]
            new[j][i] = total
            }  
        }
    }
    b.replace(new)
end
=end

def mult(a, b)
    new = Array.new(b.length) {Array.new(a[0].length, 0)}
    a[0].length.times {|i|
        b.length.times {|j|
            new[j][i] = a.length.times.inject(0) {|total, k|
                total += a[k][i] * b[j][k]
            }
        }
    }
    b.replace(new)
end

def ident(size)
    new = Array.new(size) {Array.new(size, 0)}
    size.times {|i|
        new[i][i] = 1.0
    }
    return new
end

def print_matrix(matrix)
    out = ""
    if matrix.length == 0
        return out
    end
    matrix[0].length.times {|x|
        matrix.length.times {|y|
            out = out + matrix[y][x].to_s + ' '
        }
        out = out + "\n"
    }
    puts out + "\n"
end

def add_point(matrix, x, y, z)
    new = matrix.map {|x| x}
    new.append([x, y, z, 1.0]) 
    matrix.replace(new)
end

def add_edge(matrix, x0, y0, z0, x1, y1, z1)
    add_point(matrix, x0, y0, z0)
    add_point(matrix, x1, y1, z1)
end

def draw_matrix(ary, matrix)
    new = ary.map {|a| a}
    matrix.each_slice(2) {|s|
        draw_line(new, s[0][0].to_f, s[0][1].to_f, s[1][0].to_f, s[1][1].to_f)
    }
    ary.replace(new)
end

# drawline stuff

def draw_line(ary, x0, y0, x1, y1)
    if x0 > x1
        draw_line(ary, x1, y1, x0, y0)
    else
        delta_y = y1 - y0
        delta_x = x1 - x0
        if delta_y.abs > delta_x.abs # steep slope
            if delta_y < 0 # octant 7
                draw_line7(ary, x0, y0, x1, y1)
            else # octant 2
                draw_line2(ary, x0, y0, x1, y1)
            end
        else # shallow slope
            if delta_y < 0 # octant 8
                draw_line8(ary, x0, y0, x1, y1)
            else # octant 1
                draw_line1(ary, x0, y0, x1, y1)
            end
        end
    end
end

def draw_line1(ary, x0, y0, x1, y1)
    x = x0
    y = y0
    a = y1 - y0
    b = x0 - x1
    d = 2 * a + b
    while x <= x1 do
        ary[ary.length / 2 - 1 - y][x + ary.length / 2 - 1] = [255, 255, 255, 1]
        if d > 0
            y += 1
            d += 2 * b
        end
        x += 1
        d += 2 * a 
    end
    return
end

def draw_line2(ary, x0, y0, x1, y1)
    if y0 > y1
        draw_line2(ary, x1, y1, x0, y0)
    elsif x0 == x1
        y = y0
        while y <= y1 do
            ary[ary.length / 2 - 1 - y][x0 + ary.length / 2 - 1] = [255, 255, 255, 1]
            y += 1
        end
    else
        x = x0
        y = y0
        a = y1 - y0
        b = x0 - x1
        d = 2 * b + a
        while y <= y1
            ary[ary.length / 2 - 1 - y][x + ary.length / 2 - 1] = [255, 255, 255, 1]
            if d < 0
                x += 1
                d += 2 * a
            end
            y += 1
            d += 2 * b 
        end
    end
end

def draw_line7(ary, x0, y0, x1, y1)
    if y0 < y1
        draw_line7(ary, x1, y1, x0, y0)
    else
        x = x0
        y = y0
        a = y1 - y0
        b = x0 - x1
        d = -2 * b + a
        while y >= y1 do
            ary[ary.length / 2 - 1 - y][x + ary.length / 2 - 1] = [255, 255, 255, 1]
            if d < 0
                x += 1
                d -= 2 * a
            end
            y -= 1
            d += 2 * b
        end
    end
end

def draw_line8(ary, x0, y0, x1, y1)
    x = x0
    y = y0
    a = y1 - y0
    b = x0 - x1
    d = -2 * a + b
    while x <= x1 do
        ary[ary.length / 2 - 1 - y][x + ary.length / 2 - 1] = [255, 255, 255, 1]
        if d > 0
            y -= 1
            d += 2 * b
        end
        x += 1
        d -= 2 * a 
    end
end

=begin
test_matrix = []
puts "Testing append: Appending [1, 2, 3, 4] to empty matrix M"
test_matrix.append([1, 2, 3, 4])
print_matrix(test_matrix)
puts "Testing append: Appending [5, 6, 7, 8], [9, 10, 11, 12] to M"
test_matrix.append([5, 6, 7, 8])
test_matrix.append([9, 10, 11, 12])
print_matrix(test_matrix)
puts "Creating 4 x 4 identity matrix, I:"
iden = ident(4)
print_matrix(iden)
puts "Testing identity multiplication: I * M"
mult(iden, test_matrix)
print_matrix(test_matrix)
puts "New array L: "
L = [[1, 2, 3], [2, 4, 6], [3, 6, 9], [4, 8, 12]]
print_matrix(L)
puts "Testing standard multiplication: L * M"
mult(L, test_matrix)
print_matrix(test_matrix)
=end

main(1001)
