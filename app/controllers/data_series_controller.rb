class DataSeriesController < ApplicationController
  before_action :authenticate_user!, except: [:create_endpoint, :index]
  respond_to :html, :csv

  def index
    data_point_count = 0

    # individual slugs
    @decompressed_array = []

    # some magic
    data_series_array_of_arrays = JoinedUpDataset.pluck :data_series_array

    jumbled_up = JoinedUpDataset.pluck(:id, :data_extract, :data_series_array)
    @display_attributes = []

    jumbled_up.each do |jup|

      header_definitions = jup[1]["header_definitions"]
      space_format = nil
      time_format = nil
      slug = nil

      header_definitions.each do |hd|
        temp_holder = {}

        if !hd["data_serie_slug"].nil? and !hd["key"].nil?
          slug = hd["data_serie_slug"]
          temp_holder[:display_title] = hd["key"]
        end
        if hd["types_of_data"] == "space" and !hd["format_type"].nil?
          space_format = hd["format_type"]
        end

        if hd["types_of_data"] == "time" and !hd["format_type"].nil?
          time_format = hd["format_type"]
        end

        temp_holder[:space_format] = space_format
        temp_holder[:time_format] = time_format
        temp_holder[:records_number] = jup[1]["value_extract"].size
        temp_holder[:data_serie_slug] = slug
        temp_holder[:id] = jup[0]
        @display_attributes << temp_holder if !temp_holder[:display_title].nil?
      end
    end

    data_series_array_of_arrays.each do |arr|
      arr.each do |ar|
        @decompressed_array << ar
      end
    end
    @data_serie_slugs = @decompressed_array.uniq

    @data_series = DataSerie.all
    respond_to do |format|
      format.html
      format.json { render json: DataSerie.pluck(:name) }
    end
  end

  def generate_csv

    time = params["time"]
    sector = params["sector"]
    space = params["space"]

    data_serie_slug_array = []
    params.keys.each do |key|
      # TODO -> genaralize eventually
      data_serie_slug_array << key.split("data_serie-")[1] if params[key] == "1"
    end
    # logger.info "PARAMS #{time} #{sector} #{data_serie_slug_array}"

    # get a bunch of judus with params that match the headers + dataa serie slugs

    @users = User.all
    @filename = "test.csv"
    # test creation
    csv_string = CsvShaper.encode do |csv|
      csv.headers :name, :email

      csv.rows User.all do |_csv, user|
        _csv.cells :name, :email
      end
    end
    send_data csv_string, type: 'text/csv; charset=iso-8859-1; header=present', dispotion: "attachment; filename=#{@filename}"
  end

  def show
  end

  def edit
  end

  def new
    @data_serie = DataSerie.new
  end

  def create_endpoint
    if signed_in?
      name = params[:name]
      description = params[:description]
      unit_of_measure_id = params[:unit_of_measure]
      note = params[:note]
      sector_id = params[:sector]
      tags = params[:tags]

      @data_serie = DataSerie.new
      @data_serie.name = name
      @data_serie.description = description
      @data_serie.unit_of_measure = UnitOfMeasure.where(id: unit_of_measure_id).first
      @data_serie.sector = Sector.where(id: sector_id).first
      @data_serie.note = note
      @data_serie.tags = tags


      if @data_serie.save
        render json: @data_serie, status: :created, location: @data_serie
      else
        render json: @data_serie.errors, status: :unprocessable_entity
      end
    else
      render json: {error: "You can't POST here unless you have signed in!"}
    end
  end

  def create
    @data_serie = DataSerie.create data_series_params

    respond_to do |format|
      if @data_serie.save
        format.html { redirect_to @data_serie, notice: "Data serie has been created"}
        format.json { render json: @data_serie, status: :created, location: @data_serie }
      else
        format.html { render :action => "new"}
        format.json { render json: @data_serie.errors, status: :unprocessable_entity }
      end
    end
  end


  private
    def data_series_params
      params.require(:data_serie).permit(:name, :description, :notes, :sector_id, :unit_of_measure_id)
    end

end
