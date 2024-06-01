function getInfo(filePath)
  % Load the .mat file containing metadata
  input = load(filePath);

  % Access the struct containing metadata
  metadata_struct = input.metadata.metadata; % Replace with the actual struct name

  % Initialize arrays to store major and minor axis values
  major_axis_values = [];
  minor_axis_values = [];

  % Loop through each entry in bboxes struct
  for i = 2:numel(struct2cell(metadata_struct))

      entry = struct2cell( metadata_struct){i};
      for j = 1:numel(entry.bboxes)

          bbox_entry = struct2cell(entry.bboxes){j};
            % Check if at_edge == 0
          if bbox_entry.at_edge == 0
              % Store majorAxis and minorAxis values
              major_axis_values(end+1) = bbox_entry.majorAxis;
              minor_axis_values(end+1) = bbox_entry.minorAxis;
          end

      endfor


  end

  major_axis_values = major_axis_values * 0.125;
  minor_axis_values = minor_axis_values * 0.125;
  % Calculate mean values for major and minor axis lengths
  mean_major = mean(major_axis_values);
  mean_minor = mean(minor_axis_values);

  % Determine bin edges for the histogram
  max_val = prctile([major_axis_values, minor_axis_values], 90); % Get 90th percentile
  bin_edges = linspace(min(minor_axis_values), max_val, 20);

  % Create histograms for major and minor axis values
  [counts_major, edges_major] = hist(major_axis_values, bin_edges);
  [counts_minor, edges_minor] = hist(minor_axis_values, bin_edges);

  % Plot the histograms with different colors
  figure;
  bar(edges_major, counts_major, 'hist', 'FaceColor', [0.2 0.4 0.6]);
  hold on;
  bar(edges_minor, counts_minor, 'hist', 'FaceColor', [0.8 0.2 0.2]);
  hold off;

  % Adjust title font size and display only 90% of values
  title(sprintf('Major Axis: %.2fµm +/- %.2fµm; Minor Axis: %.2fµm +/- %.2fµm', mean_major, mean_major*0.05, mean_minor, mean_minor*0.05), 'FontSize', 14);
  xlabel('Axis Length');
  ylabel('Frequency');
  legend('Major Axis', 'Minor Axis');
endfunction


