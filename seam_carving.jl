using Images, ImageView, Statistics

function draw_seam(img, seam)
    img_w_seam = copy(img)
    for i = 1:size(img)[1]
        img_w_seam[i,seam[i]] = RGB(1,1,1)
    end
    return img_w_seam
end

function write_image(img, i; filebase = "out")
    save(filebase*lpad(string(i),5,string(0))*".png", img)
end

#function to return magnitude of image elements
function brightness(image_element::AbstractRGB)
    return mean((image_element.r + image_element.g + image_element.b))
end

function find_energy(img)
    energy_x = imfilter(brightness.(img), Kernel.sobel()[2])
    energy_y = imfilter(brightness.(img), Kernel.sobel()[1])

    return sqrt.(energy_x.^2 + energy_y.^2)
end

function find_energy_map(energy)
    energy_map = zeros(size(energy))
    energy_map[end,:] = energy[end,:]

    next_elements = zeros(Int, size(energy))

    for i = size(energy)[1]-1:-1:1, j = 1:size(energy)[2]
        left = max(1,j-1)
        right = min(j+1, size(energy)[2])

        local_energy, next_element = findmin(energy_map[i+1, left:right])

        energy_map[i,j] += local_energy + energy[i,j]

        next_elements[i,j] = next_element - 2

        if left == 1
            next_elements[i,j] += 1
        end
    end
    return energy_map, next_elements
end

function find_seam_at(next_elements,element)
    seam = zeros(Int, size(next_elements)[1])
    seam[1] = element

    for i = 2:length(seam)
        seam[i] = seam[i-1] + next_elements[i, seam[i-1]]
    end
    return seam
end

function find_seam(energy)
    energy_map, next_elements = find_energy_map(energy)
    _, min_element = findmin(energy_map[1,:])

    return find_seam_at(next_elements, min_element)
end

function remove_seam(img, seam)
    img_res = (size(img)[1] , size(img)[2]-1)

    new_img = Array{RGB}(undef , img_res)

    for i = 1:length(seam)
        if seam[i] > 1 && seam[i] < size(img)[2]
            new_img[i,:] .= vcat(img[i, 1:seam[i]-1],
                                img[i, seam[i]+1:end])
        elseif seam[i] == 1
            new_img[i, :] .= img[i,2:end]
        elseif seam[i] == size(img)[2]
             new_img[i, :] .= img[i,1:end-1]
        end
    end
    return new_img
end

function seam_carving(img, res)
    if res < 0 || res > size(img)[2]
        error("resolution not acceptible")
    end

    for i = (1:size(img)[2]-res)
        energy = find_energy(img)
        seam = find_seam(energy)
        img = remove_seam(img, seam)
        write_image(img,i)
    end
end
