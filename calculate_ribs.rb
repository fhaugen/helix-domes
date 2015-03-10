#!/usr/bin/ruby

include Math

# amount of double helixes
#n = 16
n = 24

# Control the granularity of the model
step_start, steps = 0, 60

# You may want to end the lower layer earlier than the upper layer
# Set '1' to a value less than steps
step_end = { 0 => 60,
             1 => 60}

# If you're just examining the bottom and tops of the pipes,
# set renderPartial to True
renderPartial = false

# Size of the pipe
diameter_pipe = 0.84

# Size of the gap between the upper and lower layers
buffer = 0.25

pi = 3.14159265358979323846

# Diameter of the helix zome (Sketchup works in inches, thus x12)
#diameter = 9.5*12.0
diameter = 15.0*12.0
radius = diameter/2.0

# Vertical stretch & height
vs = 1.25
height = vs*(diameter/2)

# Moving the lower layer down slightly so it won't
# collide with the upper layer
height_adjust = [0]*(n/2) + [-1*(buffer+diameter_pipe)]*(n/2)

# { i } is the index of the spine (0..n-1)
spine_indices = Array(0..n-1)

# Steps from 0 -> pi
alpha = Array.new(steps) { |e| e = e * (pi*1)/(steps-0.45) }

# β = (2π / n) i
beta = spine_indices.map{|i| (2*pi/(n/2))*i}

# Set the handedness of each pipe (clockwise or counter-clockwise)
l_or_r = [1]*(n/2) + [-1]*(n/2)

points=[]

spine_indices.each_with_index { |spine_index, id|
    points_spine = []
    beta_spine = beta[spine_index]

    completed = step_end[spine_index % 2]

    alpha[step_start..completed].each { |alpha_spine|
      x = l_or_r[spine_index] * ( \
          (diameter/4) * sin(alpha_spine + beta_spine) + \
          (diameter/4) * sin(beta_spine) )
      x = x.round(3)

      y = (diameter/4) * cos(alpha_spine + beta_spine) + \
          (diameter/4) * cos(beta_spine)
      y = y.round(3)

      z = (alpha_spine/pi) * (height + height_adjust[spine_index])
      z = z.round(3)
#      z = 6

      points_spine.push([x, y, z])
    }
    points.push(points_spine)
}

c = ["red"]*(n/2) + ["blue"]*(n/2)

# Access the Entities object
model = Sketchup.active_model
entities = model.entities

if renderPartial
  points.each_with_index { |points_spine, id|
    #  if id % 3 == 0
    if points_spine[0][0] == 0 or
      points_spine[0][1] == 0 or
      points_spine[0][2] == 0

      x,y,z = 0,0,1
    else
      x = points_spine[1][0]-points_spine[0][0]
      y = points_spine[1][1]-points_spine[0][1]
      z = points_spine[1][2]-points_spine[0][2]
    end

    vector = Geom::Vector3d.new x,y,z
    vector2 = vector.normalize!
    centerpoint = Geom::Point3d.new points_spine[0]

    circle_path = entities.add_circle centerpoint, vector2, diameter_pipe/2
    circle = entities.add_face(circle_path)
    circle.material = c[id]

    path = entities.add_edges points_spine[0..5]
    circle.followme path
    #  end
  }
end

points.each_with_index { |points_spine, id|

  pt_start = 0
  pt_end = 60

  group = entities.add_group

  if points_spine[pt_start][0] == 0 or
     points_spine[pt_start][1] == 0 or
     points_spine[pt_start][2] == 0
    x,y,z = 0,0,1
  else
    x = points_spine[pt_start + 1][0]-points_spine[pt_start][0]
    y = points_spine[pt_start + 1][1]-points_spine[pt_start][1]
    z = points_spine[pt_start + 1][2]-points_spine[pt_start][2]
  end

    vector = Geom::Vector3d.new x,y,z
    vector2 = vector.normalize!
    centerpoint = Geom::Point3d.new points_spine[pt_start]

    circle_path = group.entities.add_circle centerpoint, vector2, diameter_pipe/2
    circle_sm = group.entities.add_face(circle_path)

    path = group.entities.add_edges points_spine[pt_start, pt_end]
    spiral = circle_sm.followme path

    group.material = c[id]

}

# Create the circle at the bottom of the dome for context

vector = Geom::Vector3d.new 0,0,1
vector2 = vector.normalize!

circle_big = entities.add_circle [0,0,0], vector2, radius
circle = entities.add_face(circle_big)

# the division by 12 is because the number is calculated in inches
# and we want the result in feet

print "Length of rib: " + \
((step_end[0].to_f/steps.to_f) * \
  sqrt( (diameter**2 * pi**2)/16 + height**2 )/12).round(3).to_s + "\n"

print "Length of rib: " + \
  ((step_end[0].to_f/steps.to_f) * \
  sqrt( ((radius**2 * pi**2 / 4) + height**2) )/12).round(3).to_s + "\n"


print "Height: " + (height.to_f/12.0).to_s + "\n"
